# frozen_string_literal: true

require "spec_helper"

describe "Admin manages grouped response options" do
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

  def grouped_checkbox_wrapper
    find(".questionnaire-question-grouped", visible: :all)
  end

  def grouped_checkbox_hidden?
    grouped_checkbox_wrapper[:class].to_s.split.include?("hidden")
  end

  def settings_for(groups)
    {
      "grouped" => true,
      "groups" => groups.each_with_index.map { |(id, title), idx| { "id" => id, "title" => { "en" => title }, "position" => idx } }
    }
  end

  context "when opening a saved grouped question", :js do
    let(:group_a_id) { "aaaa0001" }
    let(:group_b_id) { "bbbb0002" }
    let!(:question) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             settings: settings_for([[group_a_id, "Group A"], [group_b_id, "Group B"]]))
    end
    let!(:option_a1) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "A one" }) }
    let!(:option_a2) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "A two" }) }
    let!(:option_b1) { create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "B one" }) }

    before do
      visit questions_edit_path
      open_question_accordion(question)
    end

    it "restores the grouped checkbox as checked" do
      checkbox = find("input[type='checkbox'][name$='[grouped]']", visible: :all)
      expect(checkbox).to be_checked
    end

    it "renders each group with its title and options in the right group" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        groups = all(".questionnaire-question-group")
        expect(groups.size).to eq(2)

        within groups[0] do
          expect(page).to have_css("input[value='Group A']")
          expect(page).to have_css("input[value='A one']")
          expect(page).to have_css("input[value='A two']")
          expect(page).to have_no_css("input[value='B one']")
        end

        within groups[1] do
          expect(page).to have_css("input[value='Group B']")
          expect(page).to have_css("input[value='B one']")
          expect(page).to have_no_css("input[value='A one']")
        end
      end
    end

    it "renders position labels that reflect the current group order" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        groups = all(".questionnaire-question-group")
        expect(groups[0].find(".group-position-label").text.strip).to eq("#1")
        expect(groups[1].find(".group-position-label").text.strip).to eq("#2")
      end
    end

    it "persists grouped settings and group_ids when saving without changes" do
      click_on "Save and continue"
      expect(page).to have_admin_callout("successfully")

      question.reload
      expect(question.grouped?).to be true
      ids = question.settings["groups"].map { |g| g["id"] }
      expect(ids).to contain_exactly(group_a_id, group_b_id)

      expect(option_a1.reload.group_id).to eq(group_a_id)
      expect(option_a2.reload.group_id).to eq(group_a_id)
      expect(option_b1.reload.group_id).to eq(group_b_id)
    end
  end

  context "when toggling the grouped checkbox on an existing multiple_option question", :js do
    let!(:question) do
      create(:election_question, election:, question_type: "multiple_option").tap do |q|
        create(:election_response_option, question: q, body: { "en" => "opt1" })
        create(:election_response_option, question: q, body: { "en" => "opt2" })
        create(:election_response_option, question: q, body: { "en" => "opt3" })
      end
    end

    before do
      visit questions_edit_path
      open_question_accordion(question)
    end

    it "hides the grouped checkbox when type is single_option" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        select "Single option", from: "Type"
      end
      expect(grouped_checkbox_hidden?).to be true
    end

    it "shows the grouped checkbox again when switching back to multiple_option" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        select "Single option", from: "Type"
        expect(grouped_checkbox_hidden?).to be true

        select "Multiple option", from: "Type"
      end
      expect(grouped_checkbox_hidden?).to be false
    end

    it "clears grouped when the type is changed away from multiple_option" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        check "Group response options"
        expect(page).to have_css(".questionnaire-question-group", count: 1)

        select "Single option", from: "Type"
        expect(page).to have_no_css(".questionnaire-question-group:not(.hidden)")
      end
    end

    it "wraps existing flat options into a single auto-group when toggled on" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        check "Group response options"
        expect(page).to have_css(".questionnaire-question-group", count: 1)
        auto_group = find(".questionnaire-question-group")
        expect(auto_group).to have_css(".questionnaire-question-response-option", count: 3)
        expect(auto_group).to have_css("input[value='opt1']")
        expect(auto_group).to have_css("input[value='opt2']")
        expect(auto_group).to have_css("input[value='opt3']")
      end
    end

    it "unwraps grouped options back to the flat section when toggled off" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        check "Group response options"
        uncheck "Group response options"

        expect(page).to have_no_css(".questionnaire-question-group:not(.hidden)")
        expect(page).to have_css(".questionnaire-question-response-options-list .questionnaire-question-response-option", count: 3)
      end
    end

    it "live-updates the group title when blurring the input" do
      within "#accordion-questionnaire_question_#{question.id}-field" do
        check "Group response options"
        group = find(".questionnaire-question-group")

        within group do
          expect(find(".group-title-statement").text).to include("New group")
          title_input = find("input[name$='[title_en]']")
          title_input.set("My group")
          title_input.send_keys(:tab)
          expect(find(".group-title-statement").text).to eq("My group")
        end
      end
    end
  end

  context "when saving a newly created grouped question", :js do
    it "persists groups, titles and group_ids" do
      visit questions_edit_path
      click_on "Add question"
      click_on "Expand all questions"

      added = page.all(".questionnaire-question").last
      within added do
        fill_in find_nested_form_field_locator("body_en"), with: "Grouped question"
        select "Multiple option", from: "Type"

        page.all(".questionnaire-question-response-options-list .questionnaire-question-response-option").each_with_index do |opt, idx|
          within opt do
            fill_in find_nested_form_field_locator("body_en"), with: "flat #{idx + 1}"
          end
        end

        check "Group response options"

        first_group = all(".questionnaire-question-group").first
        within first_group do
          fill_in find_nested_form_field_locator("title_en"), with: "First group"
        end

        click_on "+ Add group"

        new_group = all(".questionnaire-question-group").last
        within new_group do
          fill_in find_nested_form_field_locator("title_en"), with: "Second group"
          new_option = all(".questionnaire-question-response-option").last
          within new_option do
            fill_in find_nested_form_field_locator("body_en"), with: "second-option-1"
          end
        end
      end

      click_on "Save and continue"
      expect(page).to have_admin_callout("successfully")

      saved = election.reload.questions.find { |q| q.body["en"] == "Grouped question" }
      expect(saved).to be_present
      expect(saved.grouped?).to be true
      titles = saved.settings["groups"].sort_by { |g| g["position"] }.map { |g| g["title"]["en"] }
      expect(titles).to eq(["First group", "Second group"])
      expect(saved.response_options.where.not(group_id: nil).count).to eq(3)
    end
  end

  context "when a grouped question has a group with options but no title" do
    let!(:question) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             settings: {
               "grouped" => true,
               "groups" => [{ "id" => "g1aaaaaa", "title" => {}, "position" => 0 }]
             })
    end
    let!(:option_a1) { create(:election_response_option, question:, group_id: "g1aaaaaa", body: { "en" => "A1" }) }
    let!(:option_a2) { create(:election_response_option, question:, group_id: "g1aaaaaa", body: { "en" => "A2" }) }

    it "blocks saving with an error callout" do
      visit questions_edit_path
      click_on "Save and continue"

      expect(page).to have_admin_callout("problem updating")
      question.reload
      expect(question.grouped?).to be true
      expect(question.settings["groups"].first["title"]).to eq({})
    end
  end

  context "when a grouped question has an empty group next to a filled group" do
    let!(:question) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             settings: {
               "grouped" => true,
               "groups" => [
                 { "id" => "g1aaaaaa", "title" => { "en" => "Filled" }, "position" => 0 },
                 { "id" => "g2bbbbbb", "title" => { "en" => "Empty" }, "position" => 1 }
               ]
             })
    end
    let!(:option_a) { create(:election_response_option, question:, group_id: "g1aaaaaa", body: { "en" => "A1" }) }
    let!(:option_b) { create(:election_response_option, question:, group_id: "g1aaaaaa", body: { "en" => "A2" }) }

    it "prunes the empty group and saves successfully" do
      visit questions_edit_path
      click_on "Save and continue"

      expect(page).to have_admin_callout("successfully")
      question.reload
      titles = question.settings["groups"].map { |g| g["title"]["en"] }
      expect(titles).to eq(["Filled"])
    end
  end

  context "when a response option references a group that no longer exists", :js do
    let!(:question) do
      create(:election_question,
             election:,
             question_type: "multiple_option",
             settings: settings_for([%w(g1aaaaaa Known)]))
    end
    let!(:known_option) { create(:election_response_option, question:, group_id: "g1aaaaaa", body: { "en" => "Known opt" }) }
    let!(:ungrouped_option) { create(:election_response_option, question:, group_id: "gunknown", body: { "en" => "Ungrouped opt" }) }

    it "renders ungrouped options in a separate fallback card" do
      visit questions_edit_path
      open_question_accordion(question)

      within "#accordion-questionnaire_question_#{question.id}-field" do
        expect(page).to have_css(".questionnaire-question-ungrouped-options")
        within ".questionnaire-question-ungrouped-options" do
          expect(page).to have_css("input[value='Ungrouped opt']")
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
