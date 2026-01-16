# frozen_string_literal: true

require "spec_helper"
require "decidim/surveys/test/factories"

module Decidim
  module Elections
    module Admin
      describe SurveyImportsController do
        let(:component) { create(:elections_component) }
        let(:organization) { component.organization }
        let(:current_user) { create(:user, :admin, :confirmed, organization:) }
        let(:surveys_component) { create(:surveys_component, participatory_space: component.participatory_space) }
        let(:survey) { create(:survey, component: surveys_component) }
        let(:questionnaire) { survey.questionnaire }
        let!(:short_response_question) { create(:questionnaire_question, questionnaire:, question_type: "short_response", body: { en: "DNI" }) }
        let!(:long_response_question) { create(:questionnaire_question, questionnaire:, question_type: "long_response", body: { en: "Comments" }) }
        let!(:single_option_question) { create(:questionnaire_question, questionnaire:, question_type: "single_option", body: { en: "Gender" }) }
        let(:census_columns) { [{ "name" => "dni", "column_type" => "alphanumeric" }] }
        let(:election) { create(:election, component:, census_manifest: "custom_csv", census_settings: { "columns" => census_columns }) }
        let(:new_election_survey_import_path) { Decidim::EngineRouter.admin_proxy(component).new_election_survey_import_path(election) }
        let(:election_survey_imports_path) { Decidim::EngineRouter.admin_proxy(component).election_survey_imports_path(election) }
        let(:election_census_updates_path) { Decidim::EngineRouter.admin_proxy(component).election_census_updates_path(election) }
        let(:survey_import_config) { { "survey_component_id" => surveys_component.id, "survey_id" => survey.id, "field_mapping" => { "dni" => short_response_question.id.to_s } } }

        before do
          request.env["decidim.current_organization"] = organization
          request.env["decidim.current_participatory_space"] = component.participatory_space
          request.env["decidim.current_component"] = component
          allow(controller).to receive(:new_election_survey_import_path).with(election).and_return(new_election_survey_import_path)
          allow(controller).to receive(:election_survey_imports_path).with(election).and_return(election_survey_imports_path)
          allow(controller).to receive(:election_census_updates_path).with(election).and_return(election_census_updates_path)
          sign_in current_user
        end

        describe "GET index" do
          context "when survey import is not configured" do
            it "redirects to new survey import page" do
              get :index, params: { election_id: election.id }

              expect(response).to redirect_to(new_election_survey_import_path)
            end
          end

          context "when survey import is configured" do
            before { election.update!(census_settings: election.census_settings.merge("survey_import" => survey_import_config)) }

            it "renders the index page" do
              get :index, params: { election_id: election.id }

              expect(response).to be_successful
              expect(response).to render_template(:index)
            end
          end
        end

        describe "GET new" do
          it "renders the new page" do
            get :new, params: { election_id: election.id }

            expect(response).to be_successful
            expect(response).to render_template(:new)
          end
        end

        describe "POST create" do
          context "with valid params" do
            let(:params) { { election_id: election.id, survey_import: { survey_component_id: surveys_component.id, survey_id: survey.id, field_mapping: { "dni" => short_response_question.id.to_s } } } }

            it "saves configuration and redirects with success message" do
              post :create, params: params

              expect(flash[:notice]).to eq(I18n.t("decidim.elections.admin.survey_imports.create.success"))
              expect(response).to redirect_to(election_survey_imports_path)
              expect(election.reload.census_settings["survey_import"]).to be_present
            end
          end

          context "with invalid params" do
            let(:params) { { election_id: election.id, survey_import: { survey_component_id: nil, survey_id: nil, field_mapping: {} } } }

            it "renders the new view with error message" do
              post :create, params: params

              expect(flash[:alert]).to eq(I18n.t("decidim.elections.admin.survey_imports.create.error"))
              expect(response).to render_template(:new)
            end
          end
        end

        describe "POST import" do
          before { election.update!(census_settings: election.census_settings.merge("survey_import" => survey_import_config)) }

          context "with valid responses" do
            let!(:respondent) { create(:user, :confirmed, organization:) }

            before { create(:response, questionnaire:, question: short_response_question, session_token: "token1", user: respondent, body: "12345678A") }

            it "enqueues import job and redirects with success message" do
              expect do
                post :import, params: { election_id: election.id }
              end.to have_enqueued_job(Decidim::ExtraCensuses::ImportFromSurveyJob)

              expect(flash[:notice]).to include("has been queued")
              expect(response).to redirect_to(election_census_updates_path)
            end
          end

          context "without valid responses" do
            it "redirects back with error message" do
              post :import, params: { election_id: election.id }

              expect(flash[:alert]).to eq(I18n.t("decidim.elections.admin.survey_imports.import.no_valid_entries"))
              expect(response).to redirect_to(election_survey_imports_path)
            end
          end
        end

        describe "GET surveys" do
          it "returns surveys for the given component as JSON" do
            get :surveys, params: { election_id: election.id, survey_component_id: surveys_component.id }

            expect(response).to be_successful
            json = response.parsed_body
            expect(json).to be_an(Array)
            expect(json.length).to eq(1)
            expect(json.first["id"]).to eq(survey.id)
          end

          it "returns empty array for non-existent component" do
            get :surveys, params: { election_id: election.id, survey_component_id: 999_999 }

            expect(response).to be_successful
            expect(response.parsed_body).to eq([])
          end
        end

        describe "GET questions" do
          it "returns only text-based questions (short_response, long_response)" do
            get :questions, params: { election_id: election.id, survey_id: survey.id }

            expect(response).to be_successful
            json = response.parsed_body
            question_ids = json.pluck("id")

            expect(question_ids).to include(short_response_question.id)
            expect(question_ids).to include(long_response_question.id)
            expect(question_ids).not_to include(single_option_question.id)
          end

          it "returns empty array for non-existent survey" do
            get :questions, params: { election_id: election.id, survey_id: 999_999 }

            expect(response).to be_successful
            expect(response.parsed_body).to eq([])
          end

          it "includes question body in response" do
            get :questions, params: { election_id: election.id, survey_id: survey.id }

            json = response.parsed_body
            dni_question = json.find { |q| q["id"] == short_response_question.id }
            expect(dni_question["body"]).to eq("DNI")
          end
        end
      end
    end
  end
end
