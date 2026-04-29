# frozen_string_literal: true

require "spec_helper"

describe "Admin manages response option groups" do
  let(:manifest_name) { "elections" }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:current_component) { create(:component, participatory_space: participatory_process, manifest_name: "elections") }
  let!(:election) { create(:election, component: current_component) }

  include_context "when managing a component as an admin"

  def questions_edit_path
    Decidim::EngineRouter.admin_proxy(current_component).edit_questions_election_path(election)
  end

  def open_question_accordion(question_record)
    find("#questionnaire_question_#{question_record.id}-button").click
  end

  describe "force one answer per group setting", :js do
    let!(:question) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             settings: {
               "grouped" => true,
               "force_one_answer_per_group" => true,
               "groups" => [
                 { "id" => "g1", "title" => { "en" => "Group 1" }, "position" => 0 },
                 { "id" => "g2", "title" => { "en" => "Group 2" }, "position" => 1 },
                 { "id" => "g3", "title" => { "en" => "Group 3" }, "position" => 2 }
               ]
             })
    end

    before do
      create(:election_response_option, question:, group_id: "g1", body: { "en" => "Option 1A" })
      create(:election_response_option, question:, group_id: "g1", body: { "en" => "Option 1B" })
      create(:election_response_option, question:, group_id: "g2", body: { "en" => "Option 2A" })
      create(:election_response_option, question:, group_id: "g2", body: { "en" => "Option 2B" })
      create(:election_response_option, question:, group_id: "g3", body: { "en" => "Option 3A" })
      create(:election_response_option, question:, group_id: "g3", body: { "en" => "Option 3B" })
      visit questions_edit_path
      open_question_accordion(question)
    end

    it "persists the force_one_answer_per_group setting with multiple groups" do
      click_on "Save and continue"
      expect(page).to have_admin_callout("successfully")

      question.reload
      expect(question.force_one_answer_per_group?).to be true
      expect(question.groups.size).to eq(3)
    end

    it "maintains the setting when adding a new group" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        click_on "+ Add group"

        new_group = all(".questionnaire-question-group").last
        within new_group do
          fill_in find_nested_form_field_locator("title_en"), with: "Group 4"

          new_option = all(".questionnaire-question-response-option").last
          within new_option do
            fill_in find_nested_form_field_locator("body_en"), with: "Option 4A"
          end
        end
      end

      click_on "Save and continue"
      expect(page).to have_admin_callout("successfully")

      question.reload
      expect(question.force_one_answer_per_group?).to be true
      expect(question.groups.size).to eq(4)
    end

    it "maintains the setting when removing a group" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        groups = all(".questionnaire-question-group")

        within groups.last do
          all(".remove-response-option").each(&:click)
        end
      end

      click_on "Save and continue"
      expect(page).to have_admin_callout("successfully")

      question.reload
      expect(question.force_one_answer_per_group?).to be true
      expect(question.groups.size).to eq(2)
    end

    it "displays all groups correctly in the admin interface" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        groups = all(".questionnaire-question-group")

        expect(groups.size).to eq(3)

        within groups[0] do
          expect(page).to have_css("input[value='Group 1']")
          expect(page).to have_css("input[value='Option 1A']")
          expect(page).to have_css("input[value='Option 1B']")
        end

        within groups[1] do
          expect(page).to have_css("input[value='Group 2']")
          expect(page).to have_css("input[value='Option 2A']")
          expect(page).to have_css("input[value='Option 2B']")
        end

        within groups[2] do
          expect(page).to have_css("input[value='Group 3']")
          expect(page).to have_css("input[value='Option 3A']")
          expect(page).to have_css("input[value='Option 3B']")
        end
      end
    end
  end

  private

  def find_nested_form_field_locator(attribute, visible: :visible)
    find_nested_form_field(attribute, visible:)["id"]
  end

  def find_nested_form_field(attribute, visible: :visible)
    current_scope.find(nested_form_field_selector(attribute), visible:, match: :first)
  end

  def nested_form_field_selector(attribute)
    "[id$=#{attribute}]"
  end
end
