# frozen_string_literal: true

require "spec_helper"
require "decidim/surveys/test/factories"

module Decidim
  module Elections
    module Admin
      describe SurveyResponsesForImport do
        subject { described_class.new(election) }

        let(:organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:elections_component) { create(:elections_component, participatory_space: participatory_process) }
        let(:surveys_component) { create(:surveys_component, participatory_space: participatory_process) }

        let(:election) do
          create(:election, component: elections_component, census_manifest: "custom_csv", census_settings:)
        end

        let(:census_settings) do
          {
            "columns" => [
              { "name" => "dni", "column_type" => "alphanumeric" },
              { "name" => "birth_date", "column_type" => "date" }
            ],
            "survey_import" => {
              "survey_component_id" => surveys_component.id,
              "survey_id" => survey.id,
              "field_mapping" => {
                "dni" => dni_question.id.to_s,
                "birth_date" => birth_date_question.id.to_s
              }
            }
          }
        end

        let(:survey) { create(:survey, component: surveys_component) }
        let(:questionnaire) { survey.questionnaire }
        let(:dni_question) do
          create(:questionnaire_question, questionnaire:, question_type: "short_response", body: { en: "DNI" })
        end
        let(:birth_date_question) do
          create(:questionnaire_question, questionnaire:, question_type: "short_response", body: { en: "Birth Date" })
        end

        describe "#query" do
          context "when survey_config is blank" do
            let(:census_settings) do
              { "columns" => [{ "name" => "dni", "column_type" => "alphanumeric" }] }
            end

            it "returns empty array" do
              expect(subject.query).to eq([])
            end
          end

          context "when survey does not exist" do
            let(:census_settings) do
              {
                "columns" => [{ "name" => "dni", "column_type" => "alphanumeric" }],
                "survey_import" => { "survey_id" => 999_999 }
              }
            end

            it "returns empty array" do
              expect(subject.query).to eq([])
            end
          end

          context "when survey has answers" do
            let!(:response1) do
              create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A")
            end
            let!(:response2) do
              create(:response, questionnaire:, question: birth_date_question, session_token: "token1", body: "1990-01-15")
            end
            let!(:response3) do
              create(:response, questionnaire:, question: dni_question, session_token: "token2", body: "87654321B")
            end
            let!(:response4) do
              create(:response, questionnaire:, question: birth_date_question, session_token: "token2", body: "1985-05-20")
            end

            it "returns array of response data hashes" do
              result = subject.query
              expect(result).to be_an(Array)
              expect(result.length).to eq(2)
            end

            it "groups answers by session_token" do
              result = subject.query
              tokens = result.map { |r| r[:session_token] }
              expect(tokens).to contain_exactly("token1", "token2")
            end

            it "includes required keys in response data" do
              result = subject.query
              response_data = result.first

              expect(response_data).to have_key(:session_token)
              expect(response_data).to have_key(:answers)
              expect(response_data).to have_key(:census_data)
              expect(response_data).to have_key(:status)
              expect(response_data).to have_key(:raw_values)
            end
          end

          context "when determining status" do
            context "when all fields are filled and not duplicate" do
              let!(:response1) do
                create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A")
              end
              let!(:response2) do
                create(:response, questionnaire:, question: birth_date_question, session_token: "token1", body: "1990-01-15")
              end

              it "status is :valid" do
                result = subject.query
                expect(result.first[:status]).to eq(:valid)
              end
            end

            context "when some fields are missing" do
              let!(:response1) do
                create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A")
              end
              # birth_date is missing

              it "status is :incomplete" do
                result = subject.query
                expect(result.first[:status]).to eq(:incomplete)
              end
            end

            context "when voter with same data exists" do
              let!(:response1) do
                create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A")
              end
              let!(:response2) do
                create(:response, questionnaire:, question: birth_date_question, session_token: "token1", body: "1990-01-15")
              end

              before do
                create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" })
              end

              it "excludes the duplicate entry from results" do
                result = subject.query
                expect(result).to be_empty
              end
            end

            context "when data has invalid format for date column" do
              let!(:response1) do
                create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A")
              end
              let!(:response2) do
                create(:response, questionnaire:, question: birth_date_question, session_token: "token1", body: "not-a-date")
              end

              it "status is :invalid" do
                result = subject.query
                expect(result.first[:status]).to eq(:invalid)
              end
            end

            context "when data has invalid format for number column" do
              let(:census_settings) do
                {
                  "columns" => [
                    { "name" => "dni", "column_type" => "alphanumeric" },
                    { "name" => "age", "column_type" => "number" }
                  ],
                  "survey_import" => {
                    "survey_component_id" => surveys_component.id,
                    "survey_id" => survey.id,
                    "field_mapping" => {
                      "dni" => dni_question.id.to_s,
                      "age" => birth_date_question.id.to_s
                    }
                  }
                }
              end

              let!(:response1) do
                create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A")
              end
              let!(:response2) do
                create(:response, questionnaire:, question: birth_date_question, session_token: "token1", body: "not-a-number")
              end

              it "status is :invalid" do
                result = subject.query
                expect(result.first[:status]).to eq(:invalid)
              end
            end

            context "when data has valid format for all column types" do
              let(:census_settings) do
                {
                  "columns" => [
                    { "name" => "dni", "column_type" => "alphanumeric" },
                    { "name" => "birth_date", "column_type" => "date" },
                    { "name" => "age", "column_type" => "number" },
                    { "name" => "notes", "column_type" => "text_trim" }
                  ],
                  "survey_import" => {
                    "survey_component_id" => surveys_component.id,
                    "survey_id" => survey.id,
                    "field_mapping" => {
                      "dni" => dni_question.id.to_s,
                      "birth_date" => birth_date_question.id.to_s,
                      "age" => age_question.id.to_s,
                      "notes" => notes_question.id.to_s
                    }
                  }
                }
              end

              let(:age_question) do
                create(:questionnaire_question, questionnaire:, question_type: "short_response", body: { en: "Age" })
              end
              let(:notes_question) do
                create(:questionnaire_question, questionnaire:, question_type: "short_response", body: { en: "Notes" })
              end

              let!(:response1) do
                create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12345678A")
              end
              let!(:response2) do
                create(:response, questionnaire:, question: birth_date_question, session_token: "token1", body: "1990-01-15")
              end
              let!(:response3) do
                create(:response, questionnaire:, question: age_question, session_token: "token1", body: "30")
              end
              let!(:response4) do
                create(:response, questionnaire:, question: notes_question, session_token: "token1", body: "  some notes  ")
              end

              it "status is :valid" do
                result = subject.query
                expect(result.first[:status]).to eq(:valid)
              end
            end
          end

          context "when building census_data" do
            let!(:response1) do
              create(:response, questionnaire:, question: dni_question, session_token: "token1", body: "12-345-678-a")
            end
            let!(:response2) do
              create(:response, questionnaire:, question: birth_date_question, session_token: "token1", body: "1990-01-15")
            end

            it "applies column type transformations" do
              result = subject.query
              census_data = result.first[:census_data]

              # alphanumeric removes special chars but preserves case
              expect(census_data["dni"]).to eq("12345678a")
            end

            it "maps question answers to census column names" do
              result = subject.query
              census_data = result.first[:census_data]

              expect(census_data).to have_key("dni")
              expect(census_data).to have_key("birth_date")
            end
          end
        end
      end
    end
  end
end
