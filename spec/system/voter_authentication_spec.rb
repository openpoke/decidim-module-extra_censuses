# frozen_string_literal: true

require "spec_helper"

describe "Voter authentication with Custom CSV census" do
  include_context "with a component"

  let(:manifest_name) { "elections" }
  let(:election) do
    create(:election, :published, :ongoing, :with_questions, component:, census_manifest: "custom_csv", census_settings: {
             "columns" => [
               { "name" => "Name", "column_type" => "text_trim" },
               { "name" => "ID", "column_type" => "alphanumeric" }
             ]
           })
  end
  let(:election_path) { Decidim::EngineRouter.main_proxy(component).election_path(election) }

  let!(:voter) do
    create(:election_voter, election:, data: { "Name" => "John Doe", "ID" => "ABC123" })
  end

  before do
    switch_to_host(organization.host)
  end

  context "when voter enters valid credentials" do
    it "successfully authenticates" do
      visit election_path
      click_on "Vote"

      fill_in "Name", with: "John Doe"
      fill_in "ID", with: "ABC123"
      click_on "Access"

      expect(page).to have_no_content("does not match any registered voter")
    end
  end

  context "when voter enters invalid credentials" do
    it "shows an error message" do
      visit election_path
      click_on "Vote"

      fill_in "Name", with: "Unknown Person"
      fill_in "ID", with: "XYZ999"
      click_on "Access"

      expect(page).to have_content("does not match any registered voter")
    end
  end

  context "when alphanumeric transformation is applied" do
    it "authenticates after removing non-alphanumeric characters" do
      visit election_path
      click_on "Vote"

      fill_in "Name", with: "John Doe"
      fill_in "ID", with: "A-B-C-1-2-3"
      click_on "Access"

      expect(page).to have_no_content("does not match any registered voter")
    end
  end

  context "when text_trim transformation is applied" do
    it "authenticates after trimming spaces" do
      visit election_path
      click_on "Vote"

      fill_in "Name", with: "  John Doe  "
      fill_in "ID", with: "ABC123"
      click_on "Access"

      expect(page).to have_no_content("does not match any registered voter")
    end
  end

  context "when using date column type" do
    let(:election) do
      create(:election, :published, :ongoing, :with_questions, component:, census_manifest: "custom_csv", census_settings: {
               "columns" => [
                 { "name" => "Name", "column_type" => "text_trim" },
                 { "name" => "BirthDate", "column_type" => "date" }
               ]
             })
    end

    let!(:voter) do
      create(:election_voter, election:, data: { "Name" => "John Doe", "BirthDate" => "1990-05-15" })
    end

    it "authenticates with date value" do
      visit election_path
      click_on "Vote"

      fill_in "Name", with: "John Doe"
      fill_in "census_data_BirthDate_date", with: "15/05/1990"
      click_on "Access"

      expect(page).to have_no_content("does not match any registered voter")
    end
  end

  context "when using number column type" do
    let(:election) do
      create(:election, :published, :ongoing, :with_questions, component:, census_manifest: "custom_csv", census_settings: {
               "columns" => [
                 { "name" => "Name", "column_type" => "text_trim" },
                 { "name" => "EmployeeID", "column_type" => "number" }
               ]
             })
    end

    let!(:voter) do
      create(:election_voter, election:, data: { "Name" => "John Doe", "EmployeeID" => "12345" })
    end

    it "authenticates with numeric value" do
      visit election_path
      click_on "Vote"

      fill_in "Name", with: "John Doe"
      fill_in "EmployeeID", with: "12345"
      click_on "Access"

      expect(page).to have_no_content("does not match any registered voter")
    end

    it "rejects invalid number format" do
      visit election_path
      click_on "Vote"

      fill_in "Name", with: "John Doe"
      fill_in "EmployeeID", with: "12345abc"
      click_on "Access"

      expect(page).to have_content("does not match any registered voter")
    end
  end
end
