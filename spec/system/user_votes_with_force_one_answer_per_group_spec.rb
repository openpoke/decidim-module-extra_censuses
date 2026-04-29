# frozen_string_literal: true

require "spec_helper"

describe "User votes with force one answer per group" do
  let(:organization) { election.organization }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:election_path) { Decidim::EngineRouter.main_proxy(election.component).election_path(election) }

  let(:group_a_id) { "aaaa0001" }
  let(:group_b_id) { "bbbb0002" }
  let(:group_c_id) { "cccc0003" }

  let(:grouped_settings) do
    {
      "grouped" => true,
      "force_one_answer_per_group" => true,
      "groups" => [
        { "id" => group_a_id, "title" => { "en" => "Animals" }, "position" => 0 },
        { "id" => group_b_id, "title" => { "en" => "Plants" }, "position" => 1 },
        { "id" => group_c_id, "title" => { "en" => "Mountains" }, "position" => 2 }
      ]
    }
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
    let!(:option_c1) { create(:election_response_option, question:, group_id: group_c_id, body: { "en" => "Everest" }) }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit election_path
      click_on "Vote"
    end

    it "shows validation error when trying to vote without selecting from all groups", :js do
      check translated_attribute(option_a1.body)

      click_on "Next"

      expect(page).to have_content("must select at least one option").or have_content("required")
    end

    it "shows validation error when skipping a group", :js do
      check translated_attribute(option_a1.body)
      check translated_attribute(option_c1.body)

      click_on "Next"

      expect(page).to have_content("must select at least one option").or have_content("required")
    end

    it "allows voting when at least one option is selected from each group" do
      check translated_attribute(option_a1.body)
      check translated_attribute(option_b1.body)
      check translated_attribute(option_c1.body)

      click_on "Next"
      click_on "Cast vote" if page.has_button?("Cast vote")

      expect(page).to have_content("successfully cast")
    end

    it "allows selecting multiple options from the same group" do
      check translated_attribute(option_a1.body)
      check translated_attribute(option_a2.body)
      check translated_attribute(option_b1.body)
      check translated_attribute(option_c1.body)

      click_on "Next"
      click_on "Cast vote" if page.has_button?("Cast vote")

      expect(page).to have_content("successfully cast")

      voter_uid = user.to_global_id.to_s
      voted_option_ids = Decidim::Elections::Vote.where(voter_uid:, question:).pluck(:response_option_id)
      expect(voted_option_ids).to contain_exactly(option_a1.id, option_a2.id, option_b1.id, option_c1.id)
    end
  end

  context "when mixing grouped questions with and without force_one_answer_per_group" do
    let!(:election) { create(:election, :published, :ongoing, :with_internal_users_census) }

    let!(:question_forced) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             settings: grouped_settings,
             body: { "en" => "Question with force (required)" },
             skip_injection: true)
    end

    let!(:question_free) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             settings: {
               "grouped" => true,
               "force_one_answer_per_group" => false,
               "groups" => [
                 { "id" => "free_a", "title" => { "en" => "Colors" }, "position" => 0 },
                 { "id" => "free_b", "title" => { "en" => "Shapes" }, "position" => 1 }
               ]
             },
             body: { "en" => "Question without force (optional)" },
             skip_injection: true)
    end

    let!(:option_a1) { create(:election_response_option, question: question_forced, group_id: group_a_id, body: { "en" => "Cat" }) }
    let!(:option_b1) { create(:election_response_option, question: question_forced, group_id: group_b_id, body: { "en" => "Oak" }) }
    let!(:option_c1) { create(:election_response_option, question: question_forced, group_id: group_c_id, body: { "en" => "Everest" }) }

    let!(:option_free_a1) { create(:election_response_option, question: question_free, group_id: "free_a", body: { "en" => "Red" }) }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit election_path
      click_on "Vote"
    end

    it "requires selection from all groups only on the forced question", :js do
      check translated_attribute(option_a1.body)
      check translated_attribute(option_b1.body)
      check translated_attribute(option_c1.body)

      click_on "Next"

      check translated_attribute(option_free_a1.body)

      click_on "Next"
      click_on "Cast vote" if page.has_button?("Cast vote")

      expect(page).to have_content("successfully cast")
    end

    it "shows error when forced question groups are not all selected", :js do
      check translated_attribute(option_a1.body)
      check translated_attribute(option_b1.body)

      click_on "Next"

      expect(page).to have_content("must select at least one option").or have_content("required")
    end
  end
end
