# frozen_string_literal: true

require "spec_helper"

describe "Admin views BORDA results" do
  let(:manifest_name) { "elections" }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
  let!(:election) { create(:election, :published_results, :with_internal_users_census, component: current_component) }

  include_context "when managing a component as an admin"

  def dashboard_path
    Decidim::EngineRouter.admin_proxy(current_component).dashboard_election_path(election)
  end

  def score_cell(option)
    page.find("[data-option-borda-score-text='#{option.question.id},#{option.id}']")
  end

  def score_percent_cell(option)
    page.find("[data-option-borda-score-percent-text='#{option.question.id},#{option.id}']")
  end

  context "with a borda question and cast votes" do
    let!(:question) do
      create(:election_question, :borda, :published_results,
             election:,
             max_choices: 3,
             body: { "en" => "Rank these" })
    end
    let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }) }
    let!(:option_b) { create(:election_response_option, question:, body: { "en" => "Beta" }) }
    let!(:option_c) { create(:election_response_option, question:, body: { "en" => "Gamma" }) }

    before do
      # start_from_max, max_choices = 3 => pts = 3 - position + 1
      # voter 1: A=1 (3), B=2 (2), C=3 (1)
      # voter 2: A=1 (3), B=2 (2)
      # totals: A=6, B=4, C=1
      create(:election_vote, question:, response_option: option_a, voter_uid: "v1", position: 1)
      create(:election_vote, question:, response_option: option_b, voter_uid: "v1", position: 2)
      create(:election_vote, question:, response_option: option_c, voter_uid: "v1", position: 3)
      create(:election_vote, question:, response_option: option_a, voter_uid: "v2", position: 1)
      create(:election_vote, question:, response_option: option_b, voter_uid: "v2", position: 2)
      visit dashboard_path
    end

    it "renders the five mockup columns including Score percentage" do
      within "#question_#{question.id} table" do
        expect(page).to have_css("thead th", count: 5)
        expect(page).to have_css("thead th", text: "Score percentage")
      end
    end

    it "renders the Score column as points straight from BordaScorer" do
      within "#question_#{question.id} table" do
        expect(score_cell(option_a)).to have_text("6 points")
        expect(score_cell(option_b)).to have_text("4 points")
        expect(score_cell(option_c)).to have_text("1 point")
      end
    end

    it "renders the Score percentage column as score over total score" do
      within "#question_#{question.id} table" do
        # total score 6 + 4 + 1 = 11
        expect(score_percent_cell(option_a)).to have_text("54.5%")
        expect(score_percent_cell(option_b)).to have_text("36.4%")
        expect(score_percent_cell(option_c)).to have_text("9.1%")
      end
    end

    it "puts total votes under Votes and total score under Score in the Total row" do
      within "#question_#{question.id} table" do
        expect(page.find("[data-question-total-votes-text]")).to have_text("5 votes")
        expect(page.find("[data-question-total-score-text]")).to have_text("11 points")
      end
    end

    it "renders rows in the question's natural option order (no score sorting)" do
      rows = page.all("#question_#{question.id} tbody tr td.w-2\\/3").map(&:text)
      expect(rows.first(3)).to eq(%w(Alpha Beta Gamma))
    end

    it "shows 0 for an option nobody ranked" do
      option_d = create(:election_response_option, question:, body: { "en" => "Delta" })
      visit dashboard_path
      within "#question_#{question.id} table" do
        expect(score_cell(option_d)).to have_text("0 points")
        expect(score_percent_cell(option_d)).to have_text("0%")
      end
    end
  end

  context "with a non-borda question" do
    let!(:question) do
      create(:election_question, :published_results,
             election:,
             question_type: "multiple_option",
             body: { "en" => "Pick some" })
    end
    let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }) }
    let!(:option_b) { create(:election_response_option, question:, body: { "en" => "Beta" }) }

    before do
      create(:election_vote, question:, response_option: option_a, voter_uid: "v1")
      visit dashboard_path
    end

    it "does not render a Score column" do
      within "#question_#{question.id} table" do
        expect(page).to have_no_css("thead th", text: "Score")
        expect(page).to have_no_css("[data-option-borda-score-text]")
        expect(page).to have_no_css("[data-option-borda-score-percent-text]")
      end
    end
  end
end
