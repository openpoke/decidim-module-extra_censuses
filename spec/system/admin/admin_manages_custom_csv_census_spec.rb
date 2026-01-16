# frozen_string_literal: true

require "spec_helper"

describe "Admin manages custom CSV census" do # rubocop:disable RSpec/DescribeClass
  let(:manifest_name) { "elections" }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
  let!(:election) { create(:election, component: current_component) }
  let(:election_census_path) { Decidim::EngineRouter.admin_proxy(current_component).election_census_path(election) }
  let(:dashboard_path) { Decidim::EngineRouter.admin_proxy(current_component).dashboard_election_path(election) }

  include_context "when managing a component as an admin"

  def fixture_path(filename)
    File.join(ENV.fetch("ENGINE_ROOT"), "spec", "fixtures", "files", filename)
  end

  before do
    visit election_census_path
  end

  it "shows the census page" do
    expect(page).to have_content("Edit election")
  end

  context "when the admin selects Custom CSV census" do
    before do
      select "Custom CSV", from: "census_manifest"
    end

    it "shows the column configuration form" do
      expect(page).to have_content("Census attributes")
      expect(page).to have_button("+ New column")
      expect(page).to have_button("Save configuration")
    end

    context "when configuring columns" do
      it "can add a new column" do
        click_on "+ New column"

        within all("[data-column-row]").last do
          expect(page).to have_css(".column-name")
          expect(page).to have_css(".column-type")
        end
      end

      it "can remove a column" do
        expect(page).to have_css("[data-column-row]", count: 1)

        click_on "+ New column"
        expect(page).to have_css("[data-column-row]", count: 2)

        within all("[data-column-row]").first do
          click_button "Delete"
        end

        expect(page).to have_css("[data-column-row]", count: 1)
      end

      it "saves column configuration" do
        within all("[data-column-row]").first do
          first("input").fill_in(with: "Name")
          first("select").select("Free text input")
        end

        click_on "+ New column"

        within all("[data-column-row]").last do
          first("input").fill_in(with: "ID")
          first("select").select("A-Z 0-9 only text")
        end

        click_on "Save configuration"

        expect(page).to have_content("Census configuration saved")
      end
    end

    context "when columns are already configured" do
      let!(:election) do
        create(:election, component: current_component, census_settings: {
                 "columns" => [
                   { "name" => "Name", "column_type" => "free_text" },
                   { "name" => "ID", "column_type" => "alphanumeric" }
                 ]
               })
      end

      before do
        visit election_census_path
        select "Custom CSV", from: "census_manifest"
      end

      it "shows current configuration" do
        expect(page).to have_content("Current configuration")
        expect(page).to have_content("Name")
        expect(page).to have_content("ID")
      end

      it "shows upload form" do
        expect(page).to have_content("Upload a CSV file")
      end

      context "when uploading a valid CSV file" do
        it "creates voters successfully" do
          dynamically_attach_file("custom_csv_file", fixture_path("valid_census.csv"))

          click_on "Save and continue"

          expect(page).to have_content("Census updated successfully")

          visit election_census_path
          select "Custom CSV", from: "census_manifest"

          expect(page).to have_content("There are currently 2 people")
        end
      end

      context "when uploading a CSV with wrong columns" do
        it "shows an error message" do
          dynamically_attach_file("custom_csv_file", fixture_path("wrong_columns.csv"))

          click_on "Save and continue"

          expect(page).to have_content("Unexpected columns")
        end
      end

      context "when uploading a malformed CSV" do
        it "shows an error message" do
          dynamically_attach_file("custom_csv_file", fixture_path("malformed.csv"))

          click_on "Save and continue"

          expect(page).to have_content("malformed")
        end
      end
    end

    context "when census data already exists" do
      let!(:election) do
        create(:election, component: current_component, census_settings: {
                 "columns" => [
                   { "name" => "Name", "column_type" => "free_text" },
                   { "name" => "ID", "column_type" => "alphanumeric" }
                 ]
               })
      end

      before do
        create(:election_voter, election:)
        visit election_census_path
        select "Custom CSV", from: "census_manifest"
      end

      it "shows remove all checkbox" do
        expect(page).to have_content("Remove all current census data")
        expect(page).to have_field("Remove all current census data")
      end

      it "requires remove_all to upload new file" do
        expect(page).to have_no_content("Upload a CSV file")
      end
    end
  end
end
