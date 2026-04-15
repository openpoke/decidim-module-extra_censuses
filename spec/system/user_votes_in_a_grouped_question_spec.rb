# frozen_string_literal: true

require "spec_helper"

describe "User votes in a grouped question" do
  let(:organization) { election.organization }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:election_path) { Decidim::EngineRouter.main_proxy(election.component).election_path(election) }

  let(:group_a_id) { "aaaa0001" }
  let(:group_b_id) { "bbbb0002" }
  let(:grouped_settings) do
    {
      "grouped" => true,
      "groups" => [
        { "id" => group_a_id, "title" => { "en" => "Animals" }, "position" => 0 },
        { "id" => group_b_id, "title" => { "en" => "Plants" }, "position" => 1 }
      ]
    }
  end

  shared_examples "renders groups and accepts a grouped vote" do
    it "renders each group with its title" do
      expect(page).to have_content("Animals")
      expect(page).to have_content("Plants")
    end

    it "shows Animals before Plants (position order)" do
      html = page.html
      expect(html.index("Animals")).to be < html.index("Plants")
    end

    it "records a vote for options picked from different groups" do
      check translated_attribute(option_a1.body)
      check translated_attribute(option_b1.body)
      click_on submit_label
      click_on "Cast vote" if page.has_button?("Cast vote")

      expect(page).to have_content("successfully cast").or have_content("already voted")
      voter_uid = user.to_global_id.to_s
      voted_option_ids = Decidim::Elections::Vote.where(voter_uid:, question:).pluck(:response_option_id)
      expect(voted_option_ids).to include(option_a1.id, option_b1.id)
    end
  end

  context "when the election is a normal (all-at-once) one" do
    let!(:election) { create(:election, :published, :ongoing, :with_internal_users_census) }
    let!(:question) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             settings: grouped_settings,
             skip_injection: true)
    end
    let!(:option_a1) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Cat" }) }
    let!(:option_a2) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Dog" }) }
    let!(:option_b1) { create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Oak" }) }
    let!(:option_b2) { create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Fern" }) }
    let(:submit_label) { "Next" }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit election_path
      click_on "Vote"
    end

    it_behaves_like "renders groups and accepts a grouped vote"

    it "renders all four response options labelled by body" do
      expect(page).to have_content("Cat")
      expect(page).to have_content("Dog")
      expect(page).to have_content("Oak")
      expect(page).to have_content("Fern")
    end

    context "when a non-grouped question exists alongside the grouped one" do
      let!(:plain_question) do
        create(:election_question,
               election:,
               question_type: "single_option",
               skip_injection: true,
               body: { "en" => "Plain question" })
      end
      let!(:plain_option_a) { create(:election_response_option, question: plain_question, body: { "en" => "plain opt 1" }) }
      let!(:plain_option_b) { create(:election_response_option, question: plain_question, body: { "en" => "plain opt 2" }) }

      it "still renders the plain question without group headings" do
        click_on "Next"
        expect(page).to have_content("plain opt 1")
        expect(page).to have_no_css(".question-group-title", text: "plain opt 1")
      end
    end

    context "when group positions are reversed" do
      let(:grouped_settings) do
        {
          "grouped" => true,
          "groups" => [
            { "id" => group_a_id, "title" => { "en" => "Animals" }, "position" => 1 },
            { "id" => group_b_id, "title" => { "en" => "Plants" }, "position" => 0 }
          ]
        }
      end

      it "respects the new ordering on the voter page" do
        html = page.html
        expect(html.index("Plants")).to be < html.index("Animals")
      end
    end
  end

  context "when the election is per_question" do
    let!(:election) { create(:election, :published, :ongoing, :with_internal_users_census, :per_question) }
    let!(:question) do
      create(:election_question, :voting_enabled,
             election:,
             question_type: "multiple_option",
             settings: grouped_settings,
             skip_injection: true)
    end
    let!(:option_a1) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Cat" }) }
    let!(:option_a2) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Dog" }) }
    let!(:option_b1) { create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Oak" }) }
    let!(:option_b2) { create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Fern" }) }
    let(:submit_label) { "Cast vote" }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit election_path
      click_on "Vote"
    end

    it_behaves_like "renders groups and accepts a grouped vote"
  end
end
