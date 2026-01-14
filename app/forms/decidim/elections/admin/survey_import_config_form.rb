# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Form for configuring survey import mapping.
      class SurveyImportConfigForm < Decidim::Form
        mimic :survey_import

        attribute :survey_component_id, Integer
        attribute :survey_id, Integer
        attribute :field_mapping, Hash

        validates :survey_component_id, presence: true
        validates :survey_id, presence: true
        validate :survey_exists
        validate :all_census_columns_mapped
        validate :questions_exist

        def election
          @election ||= context[:election]
        end

        def available_survey_components
          return [] if election.blank?

          election.component.participatory_space.components.where(manifest_name: "surveys")
        end

        def available_surveys
          return [] if survey_component_id.blank?

          Decidim::Surveys::Survey.where(decidim_component_id: survey_component_id)
        end

        def survey
          @survey ||= Decidim::Surveys::Survey.find_by(id: survey_id)
        end

        def questionnaire
          survey&.questionnaire
        end

        def available_questions
          return [] if questionnaire.blank?

          questionnaire.questions.where(question_type: %w[short_response long_response])
        end

        def census_columns
          election&.census_settings&.dig("columns") || []
        end

        def map_model(model)
          survey_config = model.census_settings&.dig("survey_import") || {}

          self.survey_component_id = survey_config["survey_component_id"]
          self.survey_id = survey_config["survey_id"]
          self.field_mapping = survey_config["field_mapping"] || {}
        end

        private

        def survey_exists
          return if survey_id.blank?

          errors.add(:survey_id, :not_found) if survey.blank?
        end

        def all_census_columns_mapped
          return if field_mapping.blank?

          mapping = field_mapping.with_indifferent_access

          census_columns.each do |col|
            column_name = col["name"]
            next if mapping[column_name].present?

            errors.add(:field_mapping, I18n.t("errors.unmapped_column", column: column_name, scope: "decidim.elections.admin.survey_imports"))
          end
        end

        def questions_exist
          return if field_mapping.blank? || questionnaire.blank?

          question_ids = questionnaire.questions.pluck(:id).map(&:to_s)

          field_mapping.each_value do |question_id|
            next if question_id.blank?
            next if question_ids.include?(question_id.to_s)

            errors.add(:field_mapping, I18n.t("errors.question_not_found", scope: "decidim.elections.admin.survey_imports"))
          end
        end
      end
    end
  end
end
