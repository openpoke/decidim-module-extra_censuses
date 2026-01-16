# frozen_string_literal: true

require "spec_helper"
require "decidim/surveys/test/factories"

module Decidim
  module Elections
    module Admin
      describe ConfigureSurveyImport do
        subject { described_class.new(form, election) }

        let(:organization) { create(:organization) }
        let(:current_user) { create(:user, :admin, :confirmed, organization:) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:elections_component) { create(:elections_component, participatory_space: participatory_process) }
        let(:surveys_component) { create(:surveys_component, participatory_space: participatory_process) }
        let(:election) do
          create(:election, component: elections_component, census_manifest: "custom_csv", census_settings: {
                   "columns" => [
                     { "name" => "dni", "column_type" => "alphanumeric" },
                     { "name" => "birth_date", "column_type" => "date" }
                   ]
                 })
        end

        let(:survey) { create(:survey, component: surveys_component) }
        let(:questionnaire) { survey.questionnaire }
        let!(:dni_question) do
          create(:questionnaire_question, questionnaire:, question_type: "short_response", body: { en: "DNI" })
        end
        let!(:birth_date_question) do
          create(:questionnaire_question, questionnaire:, question_type: "short_response", body: { en: "Birth Date" })
        end

        let(:form) do
          SurveyImportConfigForm.from_params(
            survey_component_id: surveys_component.id,
            survey_id: survey.id,
            field_mapping: {
              "dni" => dni_question.id.to_s,
              "birth_date" => birth_date_question.id.to_s
            }
          ).with_context(election:, current_user:)
        end

        describe "#call" do
          context "when form is valid" do
            it "broadcasts :ok" do
              expect { subject.call }.to broadcast(:ok)
            end

            it "updates election.census_settings with survey_import config" do
              subject.call
              election.reload

              survey_import = election.census_settings["survey_import"]
              expect(survey_import).to be_present
              expect(survey_import["survey_component_id"]).to eq(surveys_component.id)
              expect(survey_import["survey_id"]).to eq(survey.id)
            end

            it "stores field_mapping" do
              subject.call
              election.reload

              field_mapping = election.census_settings.dig("survey_import", "field_mapping")
              expect(field_mapping["dni"]).to eq(dni_question.id.to_s)
              expect(field_mapping["birth_date"]).to eq(birth_date_question.id.to_s)
            end

            it "preserves existing census_settings" do
              subject.call
              election.reload

              expect(election.census_settings["columns"]).to eq([
                                                                  { "name" => "dni", "column_type" => "alphanumeric" },
                                                                  { "name" => "birth_date", "column_type" => "date" }
                                                                ])
            end
          end

          context "when form is invalid" do
            let(:form) do
              SurveyImportConfigForm.from_params(
                survey_component_id: nil,
                survey_id: nil,
                field_mapping: {}
              ).with_context(election:)
            end

            it "broadcasts :invalid" do
              expect { subject.call }.to broadcast(:invalid)
            end

            it "does not update election.census_settings" do
              original_settings = election.census_settings.dup
              subject.call
              election.reload

              expect(election.census_settings).to eq(original_settings)
            end
          end
        end
      end
    end
  end
end
