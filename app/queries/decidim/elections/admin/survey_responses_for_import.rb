# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Query to fetch and transform survey responses for census import.
      class SurveyResponsesForImport < Decidim::Query
        def self.for(election)
          new(election).query
        end

        def initialize(election)
          @election = election
          @survey_config = election.census_settings&.dig("survey_import")
        end

        def query
          return [] if survey_config.blank? || survey.blank?

          grouped_answers.filter_map do |session_token, answers|
            census_data, raw_values = process_answers(answers)

            next if duplicate?(census_data)

            build_response_data(session_token, answers, census_data, raw_values)
          end
        end

        private

        attr_reader :election, :survey_config

        def survey
          @survey ||= Decidim::Surveys::Survey.find_by(id: survey_config["survey_id"])
        end

        def questionnaire
          survey&.questionnaire
        end

        def field_mapping
          survey_config["field_mapping"] || {}
        end

        def census_columns
          @census_columns ||= election.census_settings&.dig("columns") || []
        end

        def census_columns_index
          @census_columns_index ||= census_columns.index_by { |c| c["name"] }
        end

        def grouped_answers
          return {} if questionnaire.blank?

          question_ids = field_mapping.values.compact.map(&:to_i)
          return {} if question_ids.empty?

          answers = Decidim::Forms::Response
                    .where(questionnaire: questionnaire, decidim_question_id: question_ids)
                    .includes(:question, :choices)

          answers.group_by(&:session_token)
        end

        def build_response_data(session_token, answers, census_data, raw_values)
          {
            session_token: session_token,
            answers: answers,
            census_data: census_data,
            status: determine_status(census_data),
            raw_values: raw_values
          }
        end

        # Builds both census_data and raw_values in a single pass
        def process_answers(answers)
          answers_index = answers.index_by(&:decidim_question_id)
          census_data = {}
          raw_values = {}

          field_mapping.each do |column_name, question_id|
            answer = answers_index[question_id.to_i]
            next if answer.blank?

            raw_value = extract_answer_value(answer)
            raw_values[column_name] = raw_value

            column_def = census_columns_index[column_name]
            next if column_def.blank?

            census_data[column_name] = CustomCsvCensus::Types.transform(column_def["column_type"], raw_value.to_s)
          end

          [census_data, raw_values]
        end

        def extract_answer_value(answer)
          answer.body.presence || answer.choices&.first&.body
        end

        def determine_status(census_data)
          return :incomplete if incomplete?(census_data)
          return :invalid if invalid_format?(census_data)

          :valid
        end

        def incomplete?(census_data)
          census_columns.any? { |col| census_data[col["name"]].blank? }
        end

        def invalid_format?(census_data)
          census_columns.any? do |col|
            value = census_data[col["name"]]
            next false if value.blank?

            error = CustomCsvCensus::Types.validate(col["column_type"], value)
            error.present?
          end
        end

        def duplicate?(census_data)
          return false if census_data.blank?

          query = election.voters
          census_data.each do |name, value|
            query = query.where("data->>? = ?", name, value)
          end
          query.exists?
        end
      end
    end
  end
end
