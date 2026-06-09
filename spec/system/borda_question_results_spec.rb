# frozen_string_literal: true

require "spec_helper"

describe "BORDA question public results", driver: :rack_test do
  let!(:election) { create(:election, :published_results, :with_internal_users_census) }
  let!(:question) do
    create(:election_question, :borda, :published_results,
           election:,
           max_choices: 3,
           body: { "en" => "Rank these" })
  end
  let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }) }
  let!(:option_b) { create(:election_response_option, question:, body: { "en" => "Beta" }) }
  let!(:option_c) { create(:election_response_option, question:, body: { "en" => "Gamma" }) }
  let(:election_path) { Decidim::EngineRouter.main_proxy(election.component).election_path(election) }

  before do
    # start_from_max, max_choices = 3 => pts = 3 - position + 1
    # voter 1: A=1 (3), B=2 (2), C=3 (1); voter 2: A=1 (3), B=2 (2)
    # totals: A=6, B=4, C=1 (total 11) ; votes A=2 B=2 C=1 (total 5)
    create(:election_vote, question:, response_option: option_a, voter_uid: "v1", position: 1)
    create(:election_vote, question:, response_option: option_b, voter_uid: "v1", position: 2)
    create(:election_vote, question:, response_option: option_c, voter_uid: "v1", position: 3)
    create(:election_vote, question:, response_option: option_a, voter_uid: "v2", position: 1)
    create(:election_vote, question:, response_option: option_b, voter_uid: "v2", position: 2)
    switch_to_host(election.organization.host)
    visit election_path
  end

  it "shows each option's votes and points with a points-share percentage" do
    within "#question-#{question.id}" do
      expect(page).to have_content("2 votes, 6 points")
      expect(page).to have_content("2 votes, 4 points")
      expect(page).to have_content("1 vote, 1 point")
      expect(page).to have_content("54.5%")
      expect(page).to have_content("36.4%")
      expect(page).to have_content("9.1%")
    end
  end

  it "sizes bars by each option's share of the total points, not of the max" do
    widths = page.all(".percent-bar-width").map { |node| node[:style].to_s.delete(" ;") }
    # A=6/11=54.5, B=4/11=36.4, C=1/11=9.1 (NOT 100/66.7/16.7)
    expect(widths).to include("width:54.5%")
    expect(widths).to include("width:36.4%")
    expect(widths).to include("width:9.1%")
    expect(widths).not_to include("width:100%")
  end

  it "keeps the borda live-update hooks on the bars and scores" do
    within "#question-#{question.id}" do
      expect(page).to have_css(".percent-bar-width[data-option-borda-score-width]", count: 3)
      expect(page).to have_css("[data-option-borda-score-text]", count: 3)
    end
  end

  it "omits the upstream vote-width hooks on the bars" do
    within "#question-#{question.id}" do
      expect(page).to have_no_css(".percent-bar-width[data-option-votes-width]")
    end
  end

  it "shows a votes-and-points TOTAL footer" do
    within "#question-#{question.id}" do
      expect(page).to have_content("5 votes, 11 points")
      expect(page).to have_css("[data-question-total-votes-text='#{question.id}']")
      expect(page).to have_css("[data-question-total-score-text='#{question.id}']")
    end
  end

  it "keeps options in the question's natural order when none carry a label" do
    bodies = page.all("[data-option-body]").map(&:text)
    expect(bodies.first(3)).to eq(%w(Alpha Beta Gamma))
  end

  context "with labeled options once results are public" do
    let!(:option_a) { create(:election_response_option, :with_label, question:, body: { "en" => "Alpha" }) }

    it "renders the winner badge next to the labeled option" do
      within "#question-#{question.id}" do
        expect(page).to have_css("strong.label", text: "Winner")
      end
    end
  end
end
