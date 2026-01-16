# frozen_string_literal: true

require "spec_helper"

describe "Admin manages census updates" do
  let(:manifest_name) { "elections" }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
  let(:election) do
    create(:election, component: current_component, census_manifest: "custom_csv", census_settings: {
             "columns" => [
               { "name" => "dni", "column_type" => "alphanumeric" },
               { "name" => "birth_date", "column_type" => "date" }
             ]
           })
  end
  let(:census_updates_path) { Decidim::EngineRouter.admin_proxy(current_component).election_census_updates_path(election) }
  let(:new_census_update_path) { Decidim::EngineRouter.admin_proxy(current_component).new_election_census_update_path(election) }

  include_context "when managing a component as an admin"

  describe "Index page" do
    before do
      visit census_updates_path
    end

    it "shows the page title" do
      expect(page).to have_content("Census Status")
    end

    it "shows entries count" do
      expect(page).to have_content("0 unique entries")
    end

    context "when there are voters" do
      let!(:voter1) { create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" }) }
      let!(:voter2) { create(:election_voter, election:, data: { "dni" => "87654321B", "birth_date" => "1985-05-20" }) }

      before do
        visit census_updates_path
      end

      it "shows entries count" do
        expect(page).to have_content("2 unique entries")
      end

      it "shows the table with voters" do
        expect(page).to have_content("12345678A")
        expect(page).to have_content("87654321B")
      end

      it "shows table columns" do
        expect(page).to have_content("User identifier")
        expect(page).to have_content("Created at")
        expect(page).to have_content("Actions")
      end
    end

    context "when there are more voters than per_page" do
      before do
        create_list(:election_voter, Decidim::Paginable::OPTIONS.first + 1, election:)
        visit census_updates_path
      end

      it "shows pagination" do
        expect(page).to have_link("2")
      end
    end
  end

  describe "Search functionality" do
    let!(:voter1) { create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" }) }
    let!(:voter2) { create(:election_voter, election:, data: { "dni" => "87654321B", "birth_date" => "1985-05-20" }) }
    let!(:voter3) { create(:election_voter, election:, data: { "dni" => "11111111C", "birth_date" => "2000-12-25" }) }

    before do
      visit census_updates_path
    end

    it "finds voter by partial identifier" do
      fill_in :q, with: "123"
      click_on "Search"

      expect(page).to have_content("12345678A")
      expect(page).to have_no_content("87654321B")
      expect(page).to have_no_content("11111111C")
    end

    it "finds multiple voters matching search" do
      fill_in :q, with: "12"
      click_on "Search"

      expect(page).to have_content("12345678A")
      expect(page).to have_no_content("87654321B")
      expect(page).to have_no_content("11111111C")
    end

    it "shows all voters when search is cleared" do
      fill_in :q, with: "123"
      click_on "Search"
      expect(page).to have_no_content("87654321B")

      fill_in :q, with: ""
      click_on "Search"

      expect(page).to have_content("12345678A")
      expect(page).to have_content("87654321B")
      expect(page).to have_content("11111111C")
    end

    context "with SQL special characters" do
      let!(:voter_special) { create(:election_voter, election:, data: { "dni" => "100%test", "birth_date" => "1990-01-15" }) }

      before do
        visit census_updates_path
      end

      it "handles % character safely" do
        fill_in :q, with: "100%"
        click_on "Search"

        expect(page).to have_content("100%test")
      end
    end
  end

  describe "Adding new entry" do
    context "when election is not published" do
      before do
        visit census_updates_path
      end

      it "shows New entry button" do
        expect(page).to have_link("New entry")
      end

      it "opens new entry form" do
        click_on "New entry"

        expect(page).to have_content("New Census Entry")
        expect(page).to have_field("dni")
        expect(page).to have_field("data_birth_date_date")
      end

      it "creates entry with valid data" do
        click_on "New entry"

        fill_in "dni", with: "99999999X"
        fill_in_datepicker :data_birth_date_date, with: "15/06/1995"
        click_on "Create"

        expect(page).to have_content("Entry created successfully")
        expect(page).to have_content("99999999X")
      end

      it "shows error with empty fields" do
        click_on "New entry"
        click_on "Create"

        expect(page).to have_content("dni")
        expect(page).to have_current_path(new_census_update_path, ignore_query: true)
      end

      context "when voter already exists" do
        let(:election) do
          create(:election, component: current_component, census_manifest: "custom_csv", census_settings: {
                   "columns" => [
                     { "name" => "dni", "column_type" => "alphanumeric" },
                     { "name" => "name", "column_type" => "text_trim" }
                   ]
                 })
        end
        let!(:existing_voter) { create(:election_voter, election:, data: { "dni" => "12345678A", "name" => "John Doe" }) }

        it "shows already exists error" do
          click_on "New entry"

          fill_in "dni", with: "12345678A"
          fill_in "name", with: "John Doe"
          click_on "Create"

          expect(page).to have_content("already exists")
        end
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

      before do
        visit census_updates_path
      end

      it "does not show New entry button" do
        expect(page).to have_no_link("New entry")
      end
    end
  end

  describe "Deleting entry" do
    let!(:voter) { create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" }) }

    context "when election is not published" do
      before do
        visit census_updates_path
      end

      it "shows delete button" do
        expect(page).to have_link("Delete")
      end

      it "deletes entry after confirmation", :slow do
        expect do
          accept_confirm do
            click_on "Delete"
          end
          expect(page).to have_content("Entry deleted successfully")
        end.to change(Decidim::Elections::Voter, :count).by(-1)

        expect(page).to have_no_content("12345678A")
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

      before do
        create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" })
        visit census_updates_path
      end

      it "does not show delete buttons" do
        expect(page).to have_no_link("Delete")
      end

      it "shows voter list in read-only mode" do
        expect(page).to have_content("12345678A")
      end
    end
  end

  describe "Form fields" do
    before do
      visit new_census_update_path
    end

    it "shows all required fields" do
      expect(page).to have_field("dni")
      expect(page).to have_field("data_birth_date_date")
    end
  end
end
