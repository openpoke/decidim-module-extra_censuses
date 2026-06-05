# frozen_string_literal: true

require "spec_helper"

describe "User votes in a BORDA question" do
  let(:organization) { election.organization }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:election_path) { Decidim::EngineRouter.main_proxy(election.component).election_path(election) }

  let(:scoring_scale) { "start_from_max" }
  let(:min_choices) { 1 }
  let(:max_choices) { 3 }

  let!(:election) { create(:election, :published, :ongoing, :with_internal_users_census) }
  let!(:question) do
    create(:election_question,
           election:,
           question_type: "multiple_option",
           min_choices:,
           max_choices:,
           settings: { "voting_method" => "borda", "scoring_scale" => scoring_scale },
           skip_injection: true)
  end
  let!(:response_options) do
    %w(Alpha Bravo Charlie Delta).map { |name| create(:election_response_option, question:, body: { "en" => name }) }
  end

  def checkbox_for(option)
    find("input[type=checkbox][data-option-id='#{option.id}']")
  end

  def select_for(option)
    find("select[data-option-id='#{option.id}']", visible: :all)
  end

  def submit_button
    find("button[type=submit]", text: "Next")
  end

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit election_path
    click_on "Vote"
  end

  context "with JavaScript", :js do
    it "checking an option appends it at the end and reveals its position select" do
      checkbox_for(response_options[0]).check
      expect(select_for(response_options[0]).value).to eq("1")
      expect(select_for(response_options[0])).to be_visible

      checkbox_for(response_options[1]).check
      expect(select_for(response_options[1]).value).to eq("2")
    end

    it "unchecking renumbers the remaining options and hides the select" do
      checkbox_for(response_options[0]).check
      checkbox_for(response_options[1]).check
      checkbox_for(response_options[2]).check

      checkbox_for(response_options[0]).uncheck

      expect(select_for(response_options[1]).value).to eq("1")
      expect(select_for(response_options[2]).value).to eq("2")
      expect(select_for(response_options[0])).not_to be_visible
    end

    it "changing a position via the select uses pull-and-insert (not swap)" do
      checkbox_for(response_options[0]).check # pos 1
      checkbox_for(response_options[1]).check # pos 2
      checkbox_for(response_options[2]).check # pos 3

      select_for(response_options[2]).select(option_label(1, 3))

      expect(select_for(response_options[2]).value).to eq("1")
      expect(select_for(response_options[0]).value).to eq("2")
      expect(select_for(response_options[1]).value).to eq("3")
    end

    context "when the scoring scale starts from min" do
      let(:scoring_scale) { "start_from_min" }

      it "recomputes the points labels after each check" do
        checkbox_for(response_options[0]).check
        expect(select_for(response_options[0])).to have_text("1 point")

        checkbox_for(response_options[1]).check
        expect(select_for(response_options[0])).to have_text("2 points")
        expect(select_for(response_options[1])).to have_text("1 point")
      end
    end

    context "when min and max bound the selection" do
      let(:min_choices) { 2 }
      let(:max_choices) { 3 }

      it "disables submit below min, enables within range, and caps at max" do
        expect(submit_button).to be_disabled

        checkbox_for(response_options[0]).check
        expect(submit_button).to be_disabled

        checkbox_for(response_options[1]).check
        expect(submit_button).not_to be_disabled

        checkbox_for(response_options[2]).check
        expect(checkbox_for(response_options[3])).to be_disabled
      end
    end

    it "shows rank badges and points on the confirm page" do
      checkbox_for(response_options[0]).check
      checkbox_for(response_options[1]).check
      checkbox_for(response_options[2]).check

      submit_button.click

      within ".selected_responses" do
        expect(page).to have_text("[1]")
        expect(page).to have_text("[2]")
        expect(page).to have_text("[3]")
        expect(page).to have_text("Alpha")
        expect(page).to have_text("3 pts")
        expect(page).to have_text("2 pts")
        expect(page).to have_text("1 pt")
      end
    end

    it "persists the chosen positions on the votes table" do
      checkbox_for(response_options[0]).check
      checkbox_for(response_options[1]).check
      checkbox_for(response_options[2]).check

      submit_button.click
      click_on "Cast vote" if page.has_button?("Cast vote")

      expect(page).to have_content("successfully cast")

      voter_uid = user.to_global_id.to_s
      positions = Decidim::Elections::Vote.where(voter_uid:, question:).pluck(:response_option_id, :position).to_h
      expect(positions[response_options[0].id]).to eq(1)
      expect(positions[response_options[1].id]).to eq(2)
      expect(positions[response_options[2].id]).to eq(3)
    end
  end

  context "without JavaScript", driver: :rack_test do
    it "renders a position select for every option and accepts a valid ballot" do
      response_options.each do |option|
        expect(page).to have_css("select[data-option-id='#{option.id}']")
      end

      select option_label(1, 3), from: "response[#{question.id}][#{response_options[0].id}]"
      select option_label(2, 3), from: "response[#{question.id}][#{response_options[1].id}]"

      click_on "Next"
      click_on "Cast vote" if page.has_button?("Cast vote")

      expect(page).to have_content("successfully cast")

      voter_uid = user.to_global_id.to_s
      positions = Decidim::Elections::Vote.where(voter_uid:, question:).pluck(:response_option_id, :position).to_h
      expect(positions[response_options[0].id]).to eq(1)
      expect(positions[response_options[1].id]).to eq(2)
      expect(positions).not_to have_key(response_options[2].id)
    end
  end

  context "when the question is grouped", :js do
    let(:group_a_id) { "aaaa0001" }
    let(:group_b_id) { "bbbb0002" }
    let!(:question) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             min_choices: 1,
             max_choices: 3,
             settings: {
               "voting_method" => "borda",
               "scoring_scale" => "start_from_max",
               "grouped" => true,
               "groups" => [
                 { "id" => group_a_id, "title" => { "en" => "Animals" }, "position" => 0 },
                 { "id" => group_b_id, "title" => { "en" => "Plants" }, "position" => 1 }
               ]
             },
             skip_injection: true)
    end
    let!(:response_options) do
      [
        create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Cat" }),
        create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Oak" })
      ]
    end

    it "renders the group subheadings with per-option checkbox and select" do
      expect(page).to have_css("h3", text: "Animals")
      expect(page).to have_css("h3", text: "Plants")

      response_options.each do |option|
        expect(page).to have_css("input[type=checkbox][data-option-id='#{option.id}']")
        expect(page).to have_css("select[data-option-id='#{option.id}']", visible: :all)
      end
    end
  end

  def option_label(position, ballot_size)
    points = scoring_scale == "start_from_min" ? ballot_size - position + 1 : max_choices - position + 1
    points == 1 ? "Rank #{position} (1 point)" : "Rank #{position} (#{points} points)"
  end
end
