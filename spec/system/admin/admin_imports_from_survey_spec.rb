# frozen_string_literal: true

require "spec_helper"
require "decidim/surveys/test/factories"

describe "Admin imports from survey" do
  let(:manifest_name) { "elections" }
  let!(:surveys_component) { create(:surveys_component, participatory_space:) }
  let(:election) do
    create(:election, component: current_component, census_manifest: "custom_csv", census_settings: {
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

  let(:census_updates_path) { Decidim::EngineRouter.admin_proxy(current_component).election_census_updates_path(election) }
  let(:survey_imports_path) { Decidim::EngineRouter.admin_proxy(current_component).election_survey_imports_path(election) }
  let(:new_survey_import_path) { Decidim::EngineRouter.admin_proxy(current_component).new_election_survey_import_path(election) }

  include_context "when managing a component as an admin"

  describe "configuring survey import" do
    before do
      visit new_survey_import_path
    end

    it "displays the configuration page" do
      expect(page).to have_content("Configure Survey Import")
      expect(page).to have_content("Survey component")
    end

    context "when no survey components exist" do
      let(:surveys_component) { nil }
      let(:survey) { nil }
      let(:questionnaire) { nil }
      let(:dni_question) { nil }
      let(:birth_date_question) { nil }

      it "displays warning message" do
        expect(page).to have_content("No survey components found")
      end
    end

    context "when configuring field mapping" do
      it "displays census columns for mapping" do
        within(".table-list") do
          expect(page).to have_content("dni")
          expect(page).to have_content("birth_date")
        end
      end

      it "displays field mapping section" do
        expect(page).to have_content("Field mapping")
      end
    end
  end

  describe "import from survey button on census page" do
    before do
      visit census_updates_path
    end

    context "when election is not published" do
      it "displays Import from survey button" do
        expect(page).to have_link("Import from survey")
      end

      it "navigates to survey imports page" do
        click_on "Import from survey"
        expect(page).to have_content("Configure Survey Import").or have_content("Import from Survey")
      end
    end

    context "when election is published" do
      let(:election) do
        create(:election, :published, component: current_component, census_manifest: "custom_csv", census_settings: {
                 "columns" => [
                   { "name" => "dni", "column_type" => "alphanumeric" },
                   { "name" => "birth_date", "column_type" => "date" }
                 ]
               })
      end

      it "does not display Import from survey button" do
        expect(page).to have_no_link("Import from survey")
      end
    end
  end

  describe "viewing survey import index" do
    before do
      election.update!(census_settings: election.census_settings.merge(
                         "survey_import" => {
                           "survey_component_id" => surveys_component.id,
                           "survey_id" => survey.id,
                           "field_mapping" => {
                             "dni" => dni_question.id.to_s,
                             "birth_date" => birth_date_question.id.to_s
                           }
                         }
                       ))
    end

    context "when survey has valid responses" do
      let!(:user1) { create(:user, :confirmed, organization:) }
      let!(:user2) { create(:user, :confirmed, organization:) }

      before do
        create(:response, questionnaire:, question: dni_question, session_token: "token1", user: user1, body: "12345678A")
        create(:response, questionnaire:, question: birth_date_question, session_token: "token1", user: user1, body: "1990-01-15")
        create(:response, questionnaire:, question: dni_question, session_token: "token2", user: user2, body: "87654321B")
        create(:response, questionnaire:, question: birth_date_question, session_token: "token2", user: user2, body: "1985-05-20")

        visit survey_imports_path
      end

      it "displays the page title with survey name" do
        expect(page).to have_content("Import from Survey")
      end

      it "displays response data in table" do
        expect(page).to have_content("12345678A")
        expect(page).to have_content("87654321B")
      end

      it "displays census column headers" do
        expect(page).to have_content("dni")
        expect(page).to have_content("birth_date")
      end

      it "displays ready to import count" do
        expect(page).to have_content("Ready to import: 2")
      end

      it "displays import button with count" do
        expect(page).to have_button("Import 2 entries")
      end
    end

    context "when survey has no responses" do
      before do
        visit survey_imports_path
      end

      it "displays no responses message" do
        expect(page).to have_content("No responses found")
      end

      it "displays back to census link" do
        expect(page).to have_link("Back to census")
      end
    end

    context "when all responses are already imported (duplicates)" do
      let!(:user1) { create(:user, :confirmed, organization:) }

      before do
        create(:response, questionnaire:, question: dni_question, session_token: "token1", user: user1, body: "12345678A")
        create(:response, questionnaire:, question: birth_date_question, session_token: "token1", user: user1, body: "1990-01-15")
        create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" })

        visit survey_imports_path
      end

      it "does not display already imported entries" do
        expect(page).to have_no_content("12345678A")
      end

      it "displays no responses message since all are filtered out" do
        # When all responses are duplicates, they are excluded from query results
        # So the view shows "No responses found" (no new responses to import)
        expect(page).to have_content("No responses found")
      end
    end

    context "when response is incomplete" do
      let!(:user1) { create(:user, :confirmed, organization:) }

      before do
        create(:response, questionnaire:, question: dni_question, session_token: "token1", user: user1, body: "12345678A")
        # birth_date is missing

        visit survey_imports_path
      end

      it "counts incomplete as skipped" do
        expect(page).to have_content("Skipped: 1")
      end

      it "does not display incomplete entries in table" do
        expect(page).to have_no_css("table tbody tr")
      end
    end

    context "when responses have mixed statuses" do
      let!(:user1) { create(:user, :confirmed, organization:) }
      let!(:user2) { create(:user, :confirmed, organization:) }
      let!(:user3) { create(:user, :confirmed, organization:) }

      before do
        # Valid response
        create(:response, questionnaire:, question: dni_question, session_token: "token1", user: user1, body: "12345678A")
        create(:response, questionnaire:, question: birth_date_question, session_token: "token1", user: user1, body: "1990-01-15")
        # Invalid date format
        create(:response, questionnaire:, question: dni_question, session_token: "token2", user: user2, body: "87654321B")
        create(:response, questionnaire:, question: birth_date_question, session_token: "token2", user: user2, body: "invalid")
        # Incomplete (missing birth_date)
        create(:response, questionnaire:, question: dni_question, session_token: "token3", user: user3, body: "11111111C")

        visit survey_imports_path
      end

      it "displays ready to import count for valid entries" do
        expect(page).to have_content("Ready to import: 1")
      end

      it "displays skipped count for invalid entries" do
        expect(page).to have_content("Skipped: 2")
      end

      it "only displays valid entries in table" do
        expect(page).to have_content("12345678A")
        expect(page).to have_no_content("87654321B")
        expect(page).to have_no_content("11111111C")
      end
    end
  end

  describe "importing responses", :slow do
    include ActiveJob::TestHelper

    before do
      election.update!(census_settings: election.census_settings.merge(
                         "survey_import" => {
                           "survey_component_id" => surveys_component.id,
                           "survey_id" => survey.id,
                           "field_mapping" => {
                             "dni" => dni_question.id.to_s,
                             "birth_date" => birth_date_question.id.to_s
                           }
                         }
                       ))
    end

    let!(:user1) { create(:user, :confirmed, organization:) }
    let!(:user2) { create(:user, :confirmed, organization:) }

    before do
      create(:response, questionnaire:, question: dni_question, session_token: "token1", user: user1, body: "12345678A")
      create(:response, questionnaire:, question: birth_date_question, session_token: "token1", user: user1, body: "1990-01-15")
      create(:response, questionnaire:, question: dni_question, session_token: "token2", user: user2, body: "87654321B")
      create(:response, questionnaire:, question: birth_date_question, session_token: "token2", user: user2, body: "1985-05-20")

      visit survey_imports_path
    end

    it "enqueues import job when clicking import button" do
      expect do
        click_on "Import 2 entries"
      end.to have_enqueued_job(Decidim::ExtraCensuses::ImportFromSurveyJob)
    end

    it "displays success message after initiating import" do
      click_on "Import 2 entries"

      expect(page).to have_content("has been queued")
    end

    it "redirects to census updates page after import" do
      click_on "Import 2 entries"

      expect(page).to have_current_path(census_updates_path, ignore_query: true)
    end

    it "creates voters when job is processed" do
      perform_enqueued_jobs do
        click_on "Import 2 entries"
      end

      expect(election.voters.count).to eq(2)
    end
  end

  describe "changing survey configuration" do
    before do
      election.update!(census_settings: election.census_settings.merge(
                         "survey_import" => {
                           "survey_component_id" => surveys_component.id,
                           "survey_id" => survey.id,
                           "field_mapping" => {
                             "dni" => dni_question.id.to_s,
                             "birth_date" => birth_date_question.id.to_s
                           }
                         }
                       ))
      visit survey_imports_path
    end

    it "displays change survey button" do
      expect(page).to have_link("Change survey")
    end

    it "navigates to configuration page when clicking change survey" do
      click_on "Change survey"

      expect(page).to have_content("Configure Survey Import")
    end
  end
end
