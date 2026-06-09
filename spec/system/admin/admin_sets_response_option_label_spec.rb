# frozen_string_literal: true

require "spec_helper"

describe "Admin sets response option winner label" do
  let(:manifest_name) { "elections" }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
  let!(:election) { create(:election, :real_time, :published, :ongoing, :with_internal_users_census, component: current_component) }
  let!(:question) do
    create(:election_question, :borda, election:, max_choices: 3, body: { "en" => "Rank these" })
  end
  let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }) }
  let!(:option_b) { create(:election_response_option, :with_label, question:, body: { "en" => "Beta" }) }
  let!(:plain_question) { create(:election_question, election:, body: { "en" => "Pick one" }) }
  let!(:plain_option) { create(:election_response_option, question: plain_question, body: { "en" => "Gamma" }) }

  include_context "when managing a component as an admin"

  def dashboard_path
    Decidim::EngineRouter.admin_proxy(current_component).dashboard_election_path(election)
  end

  before { visit dashboard_path }

  context "without javascript", driver: :rack_test do
    it "renders a pencil for every option and a badge only when labeled" do
      within "#question_#{question.id}" do
        expect(page).to have_css("[data-dialog-open='label-modal-#{option_a.id}']")
        expect(page).to have_css("[data-dialog-open='label-modal-#{option_b.id}']")

        # option_b carries a label (factory trait), option_a does not
        within "table" do
          expect(page).to have_css("strong.label", text: "Winner", count: 1)
        end

        expect(page).to have_css("#label-modal-#{option_a.id} form")
        expect(page).to have_css("#label-modal-#{option_b.id} form")
      end
    end

    it "hides the label editor for questions whose results are not computed" do
      within "#question_#{plain_question.id}" do
        expect(page).to have_no_css("[data-dialog-open='label-modal-#{plain_option.id}']")
        expect(page).to have_no_css("#label-modal-#{plain_option.id}")
      end
    end

    it "renders the position field as optional with a help text" do
      within "#label-modal-#{option_a.id}" do
        expect(page).to have_css("input[name='response_option_label[position]']:not([required])")
        expect(page).to have_css(".help-text", text: "Optional")
      end
    end
  end

  context "with javascript", :js do
    it "sets a label via the modal and shows the badge" do
      find("[data-dialog-open='label-modal-#{option_a.id}']").click

      within "#label-modal-#{option_a.id}" do
        fill_in "response_option_label[title_en]", with: "Champion"
        fill_in "response_option_label[description_en]", with: "Top choice"
        fill_in "response_option_label[position]", with: "1"
        choose(option: "green", allow_label_click: false)
        click_button "Save"
      end

      within "#question_#{question.id} table" do
        expect(page).to have_css("strong.label", text: "Champion")
      end
    end

    it "updates the preview badge live" do
      find("[data-dialog-open='label-modal-#{option_a.id}']").click

      within "#label-modal-#{option_a.id}" do
        fill_in "response_option_label[title_en]", with: "Champion"
        choose(option: "green", allow_label_click: false)

        expect(page).to have_css("#label-preview-#{option_a.id}", style: /background-color:\s*rgb\(227,\s*252,\s*233\)/)
        within "#label-preview-#{option_a.id}" do
          expect(page).to have_content("Champion")
        end
      end
    end

    it "prefills the modal when reopening a labeled option" do
      find("[data-dialog-open='label-modal-#{option_b.id}']").click

      within "#label-modal-#{option_b.id}" do
        expect(find("input[name='response_option_label[title_en]']").value).to eq("Winner")
      end
    end
  end
end
