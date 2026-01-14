# frozen_string_literal: true

require "spec_helper"
require "decidim/surveys/test/factories"

module Decidim
  module Elections
    module Admin
      describe SurveyImportConfigForm do
        subject { described_class.from_params(params).with_context(election:) }

        let(:organization) { create(:organization) }
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

        let(:params) do
          {
            survey_component_id: surveys_component.id,
            survey_id: survey.id,
            field_mapping: {
              "dni" => dni_question.id.to_s,
              "birth_date" => birth_date_question.id.to_s
            }
          }
        end

        describe "#valid?" do
          context "when all attributes are valid" do
            it { is_expected.to be_valid }
          end

          context "when survey_component_id is blank" do
            let(:params) { { survey_component_id: nil, survey_id: survey.id, field_mapping: {} } }

            it { is_expected.not_to be_valid }
          end

          context "when survey_id is blank" do
            let(:params) { { survey_component_id: surveys_component.id, survey_id: nil, field_mapping: {} } }

            it { is_expected.not_to be_valid }
          end

          context "when survey does not exist" do
            let(:params) do
              {
                survey_component_id: surveys_component.id,
                survey_id: 999_999,
                field_mapping: {
                  "dni" => dni_question.id.to_s,
                  "birth_date" => birth_date_question.id.to_s
                }
              }
            end

            it { is_expected.not_to be_valid }

            it "adds :not_found error" do
              subject.valid?
              expect(subject.errors[:survey_id]).to include(I18n.t("errors.messages.not_found"))
            end
          end

          context "when a census column is not mapped" do
            let(:params) do
              {
                survey_component_id: surveys_component.id,
                survey_id: survey.id,
                field_mapping: {
                  "dni" => dni_question.id.to_s
                  # birth_date is not mapped
                }
              }
            end

            it { is_expected.not_to be_valid }

            it "adds error about unmapped column" do
              subject.valid?
              expect(subject.errors[:field_mapping].to_s).to include("birth_date")
            end
          end

          context "when mapped question does not exist" do
            let(:params) do
              {
                survey_component_id: surveys_component.id,
                survey_id: survey.id,
                field_mapping: {
                  "dni" => "999999",
                  "birth_date" => birth_date_question.id.to_s
                }
              }
            end

            it { is_expected.not_to be_valid }

            it "adds error about question not found" do
              subject.valid?
              expect(subject.errors[:field_mapping]).to be_present
            end
          end
        end

        describe "#available_survey_components" do
          context "when participatory space has survey components" do
            it "returns them" do
              expect(subject.available_survey_components).to include(surveys_component)
            end
          end

          context "when participatory space has no survey components" do
            before do
              surveys_component.destroy!
            end

            it "returns empty collection" do
              expect(subject.available_survey_components).to be_empty
            end
          end

          context "when election is blank" do
            let(:election) { nil }
            let(:params) { { survey_component_id: nil, survey_id: nil, field_mapping: {} } }

            it "returns empty array" do
              expect(subject.available_survey_components).to eq([])
            end
          end
        end

        describe "#available_surveys" do
          context "when survey_component_id is present" do
            it "returns surveys for component" do
              expect(subject.available_surveys).to include(survey)
              expect(subject.available_surveys.first.decidim_component_id).to eq(surveys_component.id)
            end
          end

          context "when survey_component_id is blank" do
            let(:params) { { survey_component_id: nil, survey_id: nil, field_mapping: {} } }

            it "returns empty collection" do
              expect(subject.available_surveys).to be_empty
            end
          end
        end

        describe "#available_questions" do
          context "when survey is present" do
            it "returns only short_response and long_response questions" do
              create(:questionnaire_question, questionnaire:, question_type: "single_option", body: { en: "Option" })

              expect(subject.available_questions).to include(dni_question, birth_date_question)
              # Note: factory :survey creates questionnaire :with_questions which adds 2 more short/long_response questions
              expect(subject.available_questions.where(question_type: %w[short_response long_response]).count).to be >= 2
            end
          end

          context "when survey is blank" do
            let(:params) { { survey_component_id: surveys_component.id, survey_id: nil, field_mapping: {} } }

            it "returns empty collection" do
              expect(subject.available_questions).to be_empty
            end
          end
        end

        describe "#census_columns" do
          it "returns columns from election.census_settings" do
            expect(subject.census_columns).to eq([
                                                   { "name" => "dni", "column_type" => "alphanumeric" },
                                                   { "name" => "birth_date", "column_type" => "date" }
                                                 ])
          end

          context "when election has no census_settings" do
            let(:election) { create(:election, component: elections_component, census_manifest: "custom_csv", census_settings: {}) }

            it "returns empty array" do
              expect(subject.census_columns).to eq([])
            end
          end
        end

        describe "#map_model" do
          let(:form) { described_class.new }

          context "when election has survey_import config" do
            before do
              election.update!(census_settings: election.census_settings.merge(
                                 "survey_import" => {
                                   "survey_component_id" => surveys_component.id,
                                   "survey_id" => survey.id,
                                   "field_mapping" => {
                                     "dni" => dni_question.id.to_s
                                   }
                                 }
                               ))
              form.with_context(election:)
              form.map_model(election)
            end

            it "populates survey_component_id" do
              expect(form.survey_component_id).to eq(surveys_component.id)
            end

            it "populates survey_id" do
              expect(form.survey_id).to eq(survey.id)
            end

            it "populates field_mapping" do
              expect(form.field_mapping).to eq({ dni: dni_question.id.to_s })
            end
          end

          context "when election has no survey_import config" do
            before do
              form.with_context(election:)
              form.map_model(election)
            end

            it "leaves survey_component_id blank" do
              expect(form.survey_component_id).to be_nil
            end

            it "leaves survey_id blank" do
              expect(form.survey_id).to be_nil
            end

            it "sets field_mapping to empty hash" do
              expect(form.field_mapping).to eq({})
            end
          end
        end
      end
    end
  end
end
