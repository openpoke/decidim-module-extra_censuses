# frozen_string_literal: true

require "spec_helper"

describe "Grouped question results and previews" do
  let(:group_a_id) { "aaaa0001" }
  let(:group_b_id) { "bbbb0002" }
  let(:grouped_settings) do
    {
      "grouped" => true,
      "groups" => [
        { "id" => group_a_id, "title" => { "en" => "Animals group" }, "position" => 0 },
        { "id" => group_b_id, "title" => { "en" => "Plants group" }, "position" => 1 }
      ]
    }
  end

  def create_grouped_question(election, *traits, **overrides)
    question = create(:election_question, *traits,
                      election:,
                      question_type: "multiple_option",
                      settings: grouped_settings,
                      skip_injection: true,
                      **overrides)
    create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Cat" })
    create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Dog" })
    create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Oak" })
    create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Fern" })
    question
  end

  context "when viewing the public election show page with published results" do
    let!(:election) { create(:election, :published_results, :with_internal_users_census) }
    let!(:question) { create_grouped_question(election, :published_results) }
    let(:election_path) { Decidim::EngineRouter.main_proxy(election.component).election_path(election) }

    before do
      switch_to_host(election.organization.host)
      visit election_path
    end

    it "renders grouped question results with group headings in position order" do
      expect(page).to have_content("Animals group")
      expect(page).to have_content("Plants group")

      html = page.html
      expect(html.index("Animals group")).to be < html.index("Plants group")
    end

    it "renders each response option under its group heading" do
      expect(page).to have_content("Cat")
      expect(page).to have_content("Dog")
      expect(page).to have_content("Oak")
      expect(page).to have_content("Fern")
    end
  end

  context "when viewing the admin dashboard for an unpublished election (questions preview)" do
    let(:manifest_name) { "elections" }
    let(:participatory_process) { create(:participatory_process, organization:) }
    let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
    let!(:election) { create(:election, :with_internal_users_census, component: current_component) }
    let!(:question) { create_grouped_question(election) }

    include_context "when managing a component as an admin"

    def dashboard_path
      Decidim::EngineRouter.admin_proxy(current_component).dashboard_election_path(election)
    end

    before do
      visit dashboard_path
    end

    it "renders group headings above their options in the questions preview" do
      expect(page).to have_content("Animals group")
      expect(page).to have_content("Plants group")
      expect(page).to have_content("Cat")
      expect(page).to have_content("Oak")

      items = page.all("h4, li").map(&:text)
      expect(items.index("Animals group")).to be < items.index("Cat")
      expect(items.index("Plants group")).to be < items.index("Oak")
    end
  end

  context "when viewing the admin dashboard for a published election (results table)" do
    let(:manifest_name) { "elections" }
    let(:participatory_process) { create(:participatory_process, organization:) }
    let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
    let!(:election) { create(:election, :published_results, :with_internal_users_census, component: current_component) }
    let!(:question) { create_grouped_question(election, :published_results) }

    include_context "when managing a component as an admin"

    def dashboard_path
      Decidim::EngineRouter.admin_proxy(current_component).dashboard_election_path(election)
    end

    before do
      visit dashboard_path
    end

    it "renders group headings as section rows within the results table" do
      expect(page).to have_content("Animals group")
      expect(page).to have_content("Plants group")
      expect(page).to have_content("Cat")
      expect(page).to have_content("Oak")

      html = page.html
      expect(html.index("Animals group")).to be < html.index("Plants group")
    end
  end

  context "when group positions are reversed" do
    let!(:election) { create(:election, :published_results, :with_internal_users_census) }
    let(:grouped_settings) do
      {
        "grouped" => true,
        "groups" => [
          { "id" => group_a_id, "title" => { "en" => "Animals group" }, "position" => 1 },
          { "id" => group_b_id, "title" => { "en" => "Plants group" }, "position" => 0 }
        ]
      }
    end
    let!(:question) { create_grouped_question(election, :published_results) }
    let(:election_path) { Decidim::EngineRouter.main_proxy(election.component).election_path(election) }

    before do
      switch_to_host(election.organization.host)
      visit election_path
    end

    it "renders results in the reversed group order" do
      html = page.html
      expect(html.index("Plants group")).to be < html.index("Animals group")
    end
  end
end
