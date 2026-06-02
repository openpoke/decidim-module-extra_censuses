# frozen_string_literal: true

require "spec_helper"

describe "BORDA question public results" do
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
    # voter 1: A=1 (3), B=2 (2), C=3 (1)
    # voter 2: A=1 (3), B=2 (2)
    # totals: A=6, B=4, C=1 ; ballots cast = 2
    create(:election_vote, question:, response_option: option_a, voter_uid: "v1", position: 1)
    create(:election_vote, question:, response_option: option_b, voter_uid: "v1", position: 2)
    create(:election_vote, question:, response_option: option_c, voter_uid: "v1", position: 3)
    create(:election_vote, question:, response_option: option_a, voter_uid: "v2", position: 1)
    create(:election_vote, question:, response_option: option_b, voter_uid: "v2", position: 2)
    switch_to_host(election.organization.host)
    visit election_path
  end

  it "shows each option's total as points, not percentage or vote count" do
    within "#question-#{question.id}" do
      expect(page).to have_content("6 points")
      expect(page).to have_content("4 points")
      expect(page).to have_content("1 point")

      expect(page).to have_no_content("%")
      expect(page).to have_no_content("votes")
    end
  end

  it "renders bars proportional to points with the top option at full width" do
    widths = page.all(".percent-bar-width").map { |node| node[:style].to_s.delete(" ;") }
    # Alpha = 6/6 = 100, Beta = 4/6 = 66.7, Gamma = 1/6 = 16.7
    expect(widths).to include("width:100%")
    expect(widths).to include("width:66.7%")
    expect(widths).to include("width:16.7%")
  end

  it "keeps options in the original question order (no score sorting)" do
    bodies = page.all("[data-option-body]").map(&:text)
    expect(bodies.first(3)).to eq(%w(Alpha Beta Gamma))
  end

  it "omits the live-update vote width hooks on the bars" do
    expect(page).to have_no_css(".percent-bar-width[data-option-votes-width]")
  end

  it "replaces the TOTAL votes footer with a ballots turnout count" do
    expect(page).to have_content("2 ballots")
    expect(page).to have_no_css("[data-question-total-votes-text='#{question.id}']")
  end
end
