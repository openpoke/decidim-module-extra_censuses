# frozen_string_literal: true

require "spec_helper"
require "decidim/surveys/test/factories"

module Decidim
  module Elections
    module Admin
      describe ImportFromSurvey do
        subject { described_class.new(election) }

        let(:organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:elections_component) { create(:elections_component, participatory_space: participatory_process) }
        let(:surveys_component) { create(:surveys_component, participatory_space: participatory_process) }
        let(:survey) { create(:survey, component: surveys_component) }
        let(:questionnaire) { survey.questionnaire }
        let(:dni_question) { create(:questionnaire_question, questionnaire:, question_type: "short_response", body: { en: "DNI" }) }
        let(:census_columns) { [{ "name" => "dni", "column_type" => "alphanumeric" }] }
        let(:survey_import_config) { { "survey_component_id" => surveys_component.id, "survey_id" => survey.id, "field_mapping" => { "dni" => dni_question.id.to_s } } }
        let(:election) { create(:election, component: elections_component, census_manifest: "custom_csv", census_settings: { "columns" => census_columns, "survey_import" => survey_import_config }) }

        describe "#call" do
          context "when no valid responses exist" do
            it "broadcasts :invalid" do
              expect { subject.call }.to broadcast(:invalid)
            end

            it "does not enqueue a job" do
              expect { subject.call }.not_to have_enqueued_job(Decidim::ExtraCensuses::ImportFromSurveyJob)
            end
          end

          context "when valid responses exist" do
            let!(:response1) { create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A") }
            let!(:response2) { create(:response, questionnaire:, question: dni_question, session_token: "token2", body: "87654321B") }

            it "broadcasts :ok with count" do
              expect { subject.call }.to broadcast(:ok, 2)
            end

            it "enqueues a background job" do
              expect { subject.call }.to have_enqueued_job(Decidim::ExtraCensuses::ImportFromSurveyJob)
            end

            it "enqueues job with correct arguments" do
              subject.call

              expect(Decidim::ExtraCensuses::ImportFromSurveyJob).to have_been_enqueued.with(
                election.id,
                array_including(hash_including("dni" => "12345678A"), hash_including("dni" => "87654321B"))
              )
            end
          end

          context "when some responses are duplicates" do
            let!(:response1) { create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A") }
            let!(:response2) { create(:response, questionnaire:, question: dni_question, session_token: "token2", body: "87654321B") }

            before { create(:election_voter, election:, data: { "dni" => "12345678A" }) }

            it "only enqueues non-duplicates" do
              subject.call

              expect(Decidim::ExtraCensuses::ImportFromSurveyJob).to have_been_enqueued.with(
                election.id,
                [hash_including("dni" => "87654321B")]
              )
            end

            it "broadcasts :ok with correct count" do
              expect { subject.call }.to broadcast(:ok, 1)
            end
          end

          context "when some responses are incomplete" do
            let!(:response1) { create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A") }
            let!(:response2) { create(:response, questionnaire:, question: dni_question, session_token: "token2", body: "") }

            it "only enqueues complete responses" do
              subject.call

              expect(Decidim::ExtraCensuses::ImportFromSurveyJob).to have_been_enqueued.with(
                election.id,
                [hash_including("dni" => "12345678A")]
              )
            end

            it "broadcasts :ok with correct count" do
              expect { subject.call }.to broadcast(:ok, 1)
            end
          end
        end
      end
    end
  end
end
