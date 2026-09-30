# frozen_string_literal: true

require "spec_helper"

describe "Admin winner label lock once results are published" do
  let(:manifest_name) { "elections" }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
  let!(:question) { create(:election_question, :borda, election:, max_choices: 3, body: { "en" => "Rank these" }) }
  let!(:option_a) { create(:election_response_option, :with_label, question:, body: { "en" => "Alpha" }) }

  include_context "when managing a component as an admin"

  def dashboard_path
    Decidim::EngineRouter.admin_proxy(current_component).dashboard_election_path(election)
  end

  before { visit dashboard_path }

  context "with an after_end election", driver: :rack_test do
    context "when results are not published yet" do
      let!(:election) { create(:election, :after_end, :published, :ongoing, :with_internal_users_census, component: current_component) }

      it "shows the pencil and the modal" do
        within "#question_#{question.id}" do
          expect(page).to have_css("[data-dialog-open='label-modal-#{option_a.id}']")
          expect(page).to have_css("#label-modal-#{option_a.id} form")
        end
      end
    end

    context "when results are published" do
      let!(:election) { create(:election, :after_end, :published_results, :with_internal_users_census, component: current_component) }

      it "hides the pencil and the modal but keeps the badge" do
        within "#question_#{question.id}" do
          expect(page).to have_no_css("[data-dialog-open='label-modal-#{option_a.id}']")
          expect(page).to have_no_css("#label-modal-#{option_a.id}")
          expect(page).to have_css("strong.label", text: "Winner")
        end
      end
    end
  end

  context "with a per_question election", driver: :rack_test do
    let!(:election) { create(:election, :per_question, :published, :ongoing, :with_internal_users_census, component: current_component) }

    context "when the question results are not published yet" do
      it "shows the pencil" do
        within "#question_#{question.id}" do
          expect(page).to have_css("[data-dialog-open='label-modal-#{option_a.id}']")
        end
      end
    end

    context "when the question results are published" do
      let!(:question) { create(:election_question, :borda, :published_results, election:, max_choices: 3, body: { "en" => "Rank these" }) }

      it "hides the pencil" do
        within "#question_#{question.id}" do
          expect(page).to have_no_css("[data-dialog-open='label-modal-#{option_a.id}']")
        end
      end
    end
  end
end
