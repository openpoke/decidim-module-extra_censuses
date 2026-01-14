# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Controller for managing census imports from surveys.
      class SurveyImportsController < Admin::ApplicationController
        helper_method :election, :survey_import_configured?, :census_columns, :configured_survey

        def index
          enforce_permission_to :update, :census, election: election

          return redirect_to new_election_survey_import_path(election) unless survey_import_configured?

          @responses = SurveyResponsesForImport.new(election).query
        end

        def new
          enforce_permission_to :update, :census, election: election
          @form = form(SurveyImportConfigForm).instance(election: election)
          @form.map_model(election)
        end

        def create
          enforce_permission_to :update, :census, election: election
          @form = form(SurveyImportConfigForm).from_params(params, election: election)

          ConfigureSurveyImport.call(@form, election) do
            on(:ok) do
              flash[:notice] = I18n.t("create.success", scope: "decidim.elections.admin.survey_imports")
              redirect_to election_survey_imports_path(election)
            end
            on(:invalid) do
              flash.now[:alert] = I18n.t("create.error", scope: "decidim.elections.admin.survey_imports")
              render :new, status: :unprocessable_entity
            end
          end
        end

        def import
          enforce_permission_to :update, :census, election: election

          ImportFromSurvey.call(election) do
            on(:ok) do |count|
              flash[:notice] = I18n.t("import.success", scope: "decidim.elections.admin.survey_imports", count: count)
              redirect_to election_census_updates_path(election)
            end
            on(:invalid) do
              flash[:alert] = I18n.t("import.no_valid_entries", scope: "decidim.elections.admin.survey_imports")
              redirect_to election_survey_imports_path(election)
            end
          end
        end

        def surveys
          enforce_permission_to :update, :census, election: election

          component_id = params[:survey_component_id]
          surveys_list = Decidim::Surveys::Survey.where(decidim_component_id: component_id).map do |survey|
            { id: survey.id, title: translated_attribute(survey.questionnaire.title) }
          end

          render json: surveys_list
        end

        def questions
          enforce_permission_to :update, :census, election: election

          survey = Decidim::Surveys::Survey.find_by(id: params[:survey_id])
          return render json: [] if survey.blank?

          questions_list = survey.questionnaire.questions
                                 .where(question_type: %w(short_response long_response))
                                 .map do |question|
            { id: question.id, body: translated_attribute(question.body) }
          end

          render json: questions_list
        end

        private

        def election
          @election ||= Decidim::Elections::Election.where(component: current_component).find(params[:election_id])
        end

        def survey_import_configured?
          election.census_settings&.dig("survey_import", "survey_id").present?
        end

        def census_columns
          election.census_settings&.dig("columns") || []
        end

        def configured_survey
          survey_id = election.census_settings&.dig("survey_import", "survey_id")
          return nil if survey_id.blank?

          @configured_survey ||= Decidim::Surveys::Survey.find_by(id: survey_id)
        end
      end
    end
  end
end
