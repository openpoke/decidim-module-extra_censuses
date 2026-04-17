# frozen_string_literal: true

require "spec_helper"

describe "Admin manages min choices for election questions" do
  let(:manifest_name) { "elections" }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
  let!(:election) { create(:election, component: current_component) }
  let!(:question) do
    create(:election_question, election:, question_type: "multiple_option").tap do |q|
      create_list(:election_response_option, 4, question: q)
    end
  end

  include_context "when managing a component as an admin"

  def questions_edit_path
    Decidim::EngineRouter.admin_proxy(current_component).edit_questions_election_path(election)
  end

  def open_question_accordion
    find("#questionnaire_question_#{question.id}-button").click
  end

  context "when persisting min_choices" do
    before do
      visit questions_edit_path
      open_question_accordion
    end

    it "defaults to 'Any' when not set" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        expect(page).to have_select("Minimum number of choices", selected: "Any")
      end
    end

    it "saves min_choices alone" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        select "2", from: "Minimum number of choices"
      end

      click_on "Save and continue"

      expect(page).to have_admin_callout("successfully")
      expect(question.reload.min_choices).to eq(2)
      expect(question.reload.max_choices).to be_nil
    end

    it "saves min_choices together with max_choices" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        select "2", from: "Minimum number of choices"
        select "3", from: "Maximum number of choices"
      end

      click_on "Save and continue"

      expect(page).to have_admin_callout("successfully")
      expect(question.reload.min_choices).to eq(2)
      expect(question.reload.max_choices).to eq(3)
    end

    context "when question already has min_choices set" do
      let!(:question) do
        create(:election_question, election:, question_type: "multiple_option", min_choices: 2, max_choices: 3).tap do |q|
          create_list(:election_response_option, 4, question: q)
        end
      end

      it "preselects the stored value" do
        within "#accordion-questionnaire_question_#{question.id}-field" do
          expect(page).to have_select("Minimum number of choices", selected: "2")
        end
      end

      it "clears min_choices when reset to 'Any'" do
        within "#accordion-questionnaire_question_#{question.id}-field" do
          select "Any", from: "Minimum number of choices"
        end

        click_on "Save and continue"

        expect(page).to have_admin_callout("successfully")
        expect(question.reload.min_choices).to be_nil
      end
    end
  end

  context "with dynamic UI behavior", :js do
    before do
      visit questions_edit_path
      open_question_accordion
    end

    it "hides min_choices when question type is single_option" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        select "Single option", from: "Type"
        expect(page).to have_no_content("Minimum number of choices")
      end
    end

    it "shows min_choices again when switching back to multiple_option" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        select "Single option", from: "Type"
        expect(page).to have_no_content("Minimum number of choices")

        select "Multiple option", from: "Type"
        expect(page).to have_content("Minimum number of choices")
      end
    end

    it "caps min_choices options by selected max_choices" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        select "2", from: "Maximum number of choices"

        min_select = find("select[name$='[min_choices]']")
        values = min_select.all("option").map(&:value).reject(&:empty?)
        expect(values).to eq(%w(1 2))
      end
    end

    it "lists min_choices up to number of response options when max_choices is blank" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        min_select = find("select[name$='[min_choices]']")
        values = min_select.all("option").map(&:value).reject(&:empty?)
        expect(values).to eq(%w(1 2 3 4))
      end
    end
  end
end
