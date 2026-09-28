# frozen_string_literal: true

require "spec_helper"

describe "Admin views question meta line", driver: :rack_test do
  let(:manifest_name) { "elections" }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
  let!(:election) { create(:election, :with_internal_users_census, component: current_component) }

  include_context "when managing a component as an admin"

  def dashboard_path
    Decidim::EngineRouter.admin_proxy(current_component).dashboard_election_path(election)
  end

  context "with a borda question" do
    let!(:question) do
      create(:election_question, :borda,
             election:,
             max_choices: 5,
             body: { "en" => "Rank these" })
    end

    before { visit dashboard_path }

    it "renders the borda and choices chips" do
      expect(page).to have_content("Standard Borda count")
      expect(page).to have_content("Choose 1–5")
    end
  end

  context "with a plain approval question and no constraints" do
    let!(:question) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             max_choices: nil,
             min_choices: nil,
             body: { "en" => "Pick some" })
    end

    before { visit dashboard_path }

    it "renders no meta chips" do
      expect(page).to have_no_text("Borda")
      expect(page).to have_no_text("Choose")
    end
  end

  context "with published results (results dashboard)" do
    let!(:election) { create(:election, :published_results, :with_internal_users_census, component: current_component) }
    let!(:question) do
      create(:election_question, :borda, :published_results,
             election:,
             max_choices: 5,
             body: { "en" => "Rank these" })
    end

    before { visit dashboard_path }

    it "renders the meta chips in the results question heading" do
      expect(page).to have_content("Standard Borda count")
      expect(page).to have_content("Choose 1–5")
    end
  end
end
