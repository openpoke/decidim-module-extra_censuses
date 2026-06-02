# frozen_string_literal: true

require "spec_helper"

describe "Admin manages BORDA voting for election questions" do
  let(:manifest_name) { "elections" }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
  let!(:election) { create(:election, component: current_component) }
  let!(:question) do
    create(:election_question, election:, question_type: "multiple_option", max_choices: 3).tap do |q|
      create_list(:election_response_option, 4, question: q)
    end
  end

  include_context "when managing a component as an admin"

  def questions_edit_path
    Decidim::EngineRouter.admin_proxy(current_component).edit_questions_election_path(election)
  end

  def open_question_accordion(question_record = question)
    find("#questionnaire_question_#{question_record.id}-button").click
  end

  def borda_checkbox
    find("input[type='checkbox'][name$='[voting_method]']", visible: :all)
  end

  def scoring_scale_select
    find("select[name$='[scoring_scale]']", visible: :all)
  end

  context "when persisting BORDA settings" do
    before do
      visit questions_edit_path
      open_question_accordion
    end

    it "renders the checkbox and the scoring-scale select unchecked by default" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        expect(page).to have_field(
          I18n.t("borda_label", scope: "decidim.extra_censuses.elections.admin.questions"),
          type: "checkbox"
        )
        expect(borda_checkbox).not_to be_checked
        expect(page).to have_select(
          I18n.t("scoring_scale_label", scope: "decidim.extra_censuses.elections.admin.questions"),
          visible: :all
        )
      end
    end

    it "persists voting_method = borda and scoring_scale = start_from_max on save" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        check I18n.t("borda_label", scope: "decidim.extra_censuses.elections.admin.questions")
      end

      click_on "Save and continue"
      expect(page).to have_admin_callout("successfully")

      question.reload
      expect(question.settings["voting_method"]).to eq("borda")
      expect(question.settings["scoring_scale"]).to eq("start_from_max")
    end

    context "when question already has BORDA enabled" do
      let!(:question) do
        create(:election_question, :borda, election:).tap do |q|
          create_list(:election_response_option, 4, question: q)
        end
      end

      it "preselects the checkbox and scoring_scale" do
        within "#accordion-questionnaire_question_#{question.id}-field" do
          expect(borda_checkbox).to be_checked
          expect(scoring_scale_select.value).to eq("start_from_max")
        end
      end
    end
  end

  context "with dynamic UI behavior", :js do
    before do
      visit questions_edit_path
      open_question_accordion
    end

    it "hides the scoring-scale select until the checkbox is checked" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        expect(page).to have_css(".questionnaire-question-scoring-scale.hidden", visible: :all)

        check I18n.t("borda_label", scope: "decidim.extra_censuses.elections.admin.questions")
        expect(page).to have_no_css(".questionnaire-question-scoring-scale.hidden", visible: :all)
      end
    end

    it "hides the scoring-scale select again and resets it when the checkbox is unchecked" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        check I18n.t("borda_label", scope: "decidim.extra_censuses.elections.admin.questions")
        select I18n.t("scoring_scale_options.start_from_min", scope: "decidim.extra_censuses.elections.admin.questions"),
               from: I18n.t("scoring_scale_label", scope: "decidim.extra_censuses.elections.admin.questions")

        uncheck I18n.t("borda_label", scope: "decidim.extra_censuses.elections.admin.questions")
        expect(page).to have_css(".questionnaire-question-scoring-scale.hidden", visible: :all)
        expect(scoring_scale_select.value).to eq("start_from_max")
      end
    end

    it "hides the BORDA wrapper when question type is single_option" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        select "Single option", from: "Type"
        expect(page).to have_css(".questionnaire-question-borda.hidden", visible: :all)
      end
    end
  end

  context "when the election has at least one vote on the question" do
    let!(:question) do
      create(:election_question, election:, question_type: "multiple_option", max_choices: 3).tap do |q|
        opts = create_list(:election_response_option, 4, question: q)
        create(:election_vote, question: q, response_option: opts.first)
      end
    end

    it "redirects away from the edit_questions form via the existing permission gate" do
      visit questions_edit_path

      expect(page).to have_content("You are not authorized to perform this action")
      expect(page).to have_no_css("#questionnaire_question_#{question.id}-button")
    end
  end

  context "when the question has max_choices = 1" do
    let!(:question) do
      create(:election_question, election:, question_type: "multiple_option", max_choices: 1).tap do |q|
        create_list(:election_response_option, 4, question: q)
      end
    end

    before do
      visit questions_edit_path
      open_question_accordion
    end

    it "rejects the submission with a validation error when BORDA is enabled" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        expect(borda_checkbox).not_to be_disabled
        check I18n.t("borda_label", scope: "decidim.extra_censuses.elections.admin.questions")
      end

      click_on "Save and continue"

      expect(page).to have_admin_callout("problem")
      expect(question.reload.settings["voting_method"]).to be_blank
    end
  end
end
