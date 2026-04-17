# frozen_string_literal: true

require "spec_helper"

describe "User votes with choices range constraints" do
  let(:organization) { election.organization }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:election_path) { Decidim::EngineRouter.main_proxy(election.component).election_path(election) }

  def select_options(count)
    response_options.first(count).each do |option|
      check translated_attribute(option.body)
    end
  end

  shared_examples "enforces choices range constraints" do
    context "with no range set" do
      let(:min_choices) { nil }
      let(:max_choices) { nil }

      it "accepts any multi-option selection" do
        select_options(3)
        click_on submit_label
        expect(page).to have_no_content("You must select")
        expect(page).to have_no_content("You cannot select")
      end
    end

    context "with only max_choices set" do
      let(:min_choices) { nil }
      let(:max_choices) { 3 }

      it "accepts a selection within the max" do
        select_options(3)
        click_on submit_label
        expect(page).to have_no_content("You cannot select more")
      end

      it "blocks a selection above the max" do
        select_options(4)
        click_on submit_label
        expect(page).to have_content("You cannot select more than 3 options")
      end
    end

    context "with only min_choices set" do
      let(:min_choices) { 2 }
      let(:max_choices) { nil }

      it "accepts a selection meeting the min" do
        select_options(2)
        click_on submit_label
        expect(page).to have_no_content("You must select at least")
      end

      it "blocks a selection below the min" do
        select_options(1)
        click_on submit_label
        expect(page).to have_content("You must select at least 2 options")
      end
    end

    context "with both min_choices and max_choices set" do
      let(:min_choices) { 2 }
      let(:max_choices) { 3 }

      it "accepts a selection within the range" do
        select_options(2)
        click_on submit_label
        expect(page).to have_no_content("You must select between")
      end

      it "blocks a selection below the range" do
        select_options(1)
        click_on submit_label
        expect(page).to have_content("You must select between 2 and 3 options")
      end

      it "blocks a selection above the range" do
        select_options(4)
        click_on submit_label
        expect(page).to have_content("You must select between 2 and 3 options")
      end
    end
  end

  context "when the election is a normal (all-at-once) one" do
    let!(:election) { create(:election, :published, :ongoing, :with_internal_users_census) }
    let!(:question) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             min_choices:,
             max_choices:,
             skip_injection: true)
    end
    let!(:response_options) do
      create_list(:election_response_option, 5, question:)
    end
    let(:submit_label) { "Next" }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit election_path
      click_on "Vote"
    end

    it_behaves_like "enforces choices range constraints"
  end

  context "when the election is per_question" do
    let!(:election) { create(:election, :published, :ongoing, :with_internal_users_census, :per_question) }
    let!(:question) do
      create(:election_question, :voting_enabled,
             election:,
             question_type: "multiple_option",
             min_choices:,
             max_choices:,
             skip_injection: true)
    end
    let!(:response_options) do
      create_list(:election_response_option, 5, question:)
    end
    let(:submit_label) { "Cast vote" }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit election_path
      click_on "Vote"
    end

    it_behaves_like "enforces choices range constraints"
  end
end
