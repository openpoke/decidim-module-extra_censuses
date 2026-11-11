# frozen_string_literal: true

require "spec_helper"

describe "User votes with an exclusive option", :js do
  let(:organization) { election.organization }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:election_path) { Decidim::EngineRouter.main_proxy(election.component).election_path(election) }
  let(:settings) { { "exclusive_option" => true } }

  let!(:election) { create(:election, :published, :ongoing, :with_internal_users_census) }
  let!(:question) do
    create(:election_question, election:, question_type: "multiple_option", settings:, skip_injection: true).tap do |q|
      create(:election_response_option, question: q, body: { "en" => "Alpha" }, group_id: "aaaa0001")
      create(:election_response_option, question: q, body: { "en" => "Bravo" }, group_id: "bbbb0002")
      create(:election_response_option, question: q, body: { "en" => "Blank vote" }, settings: { "exclusive" => true })
    end
  end

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit election_path
    click_on "Vote"
  end

  it "unchecks and disables the other options when checked" do
    check "Alpha"
    check "Blank vote"

    expect(page).to have_unchecked_field("Alpha", disabled: true)
    expect(page).to have_field("Bravo", disabled: true)
  end

  context "when the question forces one answer per group" do
    let(:settings) do
      {
        "exclusive_option" => true, "grouped" => true, "force_one_answer_per_group" => true,
        "groups" => [
          { "id" => "aaaa0001", "title" => { "en" => "Animals" }, "position" => 0 },
          { "id" => "bbbb0002", "title" => { "en" => "Plants" }, "position" => 1 }
        ]
      }
    end

    it "lets the blank vote through to the confirmation" do
      check "Blank vote"
      click_on "Next"

      expect(page).to have_css(".selected_responses", text: "Blank vote")
    end
  end
end
