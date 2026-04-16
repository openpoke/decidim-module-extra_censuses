# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      describe UpdateQuestions do
        let(:organization) { create(:organization) }
        let(:current_user) { create(:user, :admin, :confirmed, organization:) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:elections_component, participatory_space: participatory_process) }
        let(:election) { create(:election, component:) }
        let(:context_params) { { current_organization: organization, current_user: } }

        let!(:existing_question) do
          create(:election_question, :with_response_options,
                 election:,
                 body: { en: "Existing" },
                 description: { en: "Existing desc" },
                 position: 0)
        end

        let(:existing_option1) { existing_question.response_options.first }
        let(:existing_option2) { existing_question.response_options.second }

        describe "min_choices persistence" do
          context "when updating an existing question with min_choices" do
            let(:params) do
              {
                "questions" => [
                  {
                    "id" => existing_question.id,
                    "body" => existing_question.body,
                    "description" => existing_question.description,
                    "question_type" => "multiple_option",
                    "min_choices" => 2,
                    "max_choices" => 2,
                    "response_options" => [
                      { "id" => existing_option1.id, "body" => existing_option1.body },
                      { "id" => existing_option2.id, "body" => existing_option2.body }
                    ]
                  }
                ]
              }
            end

            let(:form) { QuestionsForm.from_params(params).with_context(context_params) }
            let(:command) { described_class.new(form, election) }

            it "saves the min_choices value" do
              command.call
              expect(existing_question.reload.min_choices).to eq(2)
            end

            it "saves max_choices alongside min_choices" do
              command.call
              expect(existing_question.reload.max_choices).to eq(2)
            end
          end

          context "when updating an existing question and clearing min_choices" do
            before do
              existing_question.update!(min_choices: 2)
            end

            let(:params) do
              {
                "questions" => [
                  {
                    "id" => existing_question.id,
                    "body" => existing_question.body,
                    "description" => existing_question.description,
                    "question_type" => "multiple_option",
                    "min_choices" => "",
                    "response_options" => [
                      { "id" => existing_option1.id, "body" => existing_option1.body },
                      { "id" => existing_option2.id, "body" => existing_option2.body }
                    ]
                  }
                ]
              }
            end

            let(:form) { QuestionsForm.from_params(params).with_context(context_params) }
            let(:command) { described_class.new(form, election) }

            it "clears the min_choices value" do
              command.call
              expect(existing_question.reload.min_choices).to be_nil
            end
          end

          context "when adding a new question with min_choices" do
            let(:params) do
              {
                "questions" => [
                  {
                    "body" => { en: "Brand new" },
                    "description" => { en: "Description" },
                    "question_type" => "multiple_option",
                    "min_choices" => 2,
                    "max_choices" => 3,
                    "response_options" => [
                      { "body" => { en: "Opt 1" } },
                      { "body" => { en: "Opt 2" } },
                      { "body" => { en: "Opt 3" } },
                      { "body" => { en: "Opt 4" } }
                    ]
                  }
                ]
              }
            end

            let(:form) { QuestionsForm.from_params(params).with_context(context_params) }
            let(:command) { described_class.new(form, election) }

            it "creates the new question with min_choices set" do
              expect { command.call }.to change { election.reload.questions.count }.by(1)
              new_question = election.reload.questions.order(:position).last
              expect(translated(new_question.body)).to eq("Brand new")
              expect(new_question.min_choices).to eq(2)
              expect(new_question.max_choices).to eq(3)
            end
          end
        end

        describe "grouped persistence" do
          context "when persisting a brand new grouped question" do
            let(:params) do
              {
                "questions" => [
                  {
                    "body" => { en: "Grouped question" },
                    "description" => { en: "Desc" },
                    "question_type" => "multiple_option",
                    "grouped" => "1",
                    "groups" => {
                      "0" => { "id" => "g1aaaaaa", "title_en" => "First", "position" => 0 },
                      "1" => { "id" => "g2bbbbbb", "title_en" => "Second", "position" => 1 }
                    },
                    "response_options" => {
                      "0" => { "body" => { en: "Opt 1" }, "group_id" => "g1aaaaaa" },
                      "1" => { "body" => { en: "Opt 2" }, "group_id" => "g2bbbbbb" }
                    }
                  }
                ]
              }
            end

            let(:form) { QuestionsForm.from_params(params).with_context(context_params) }
            let(:command) { described_class.new(form, election) }

            it "stores grouped=true in settings" do
              command.call
              new_question = election.reload.questions.order(:position).last
              expect(new_question.settings["grouped"]).to be true
            end

            it "stores groups in settings with id, title and position" do
              command.call
              new_question = election.reload.questions.order(:position).last
              groups = new_question.settings["groups"]
              expect(groups.size).to eq(2)
              expect(groups.map { |g| g["id"] }).to contain_exactly("g1aaaaaa", "g2bbbbbb")
              expect(groups.find { |g| g["id"] == "g1aaaaaa" }["title"]).to eq("en" => "First")
            end

            it "stores group_id on each response option" do
              command.call
              new_question = election.reload.questions.order(:position).last
              by_body = new_question.response_options.index_by { |o| o.body["en"] }
              expect(by_body["Opt 1"].group_id).to eq("g1aaaaaa")
              expect(by_body["Opt 2"].group_id).to eq("g2bbbbbb")
            end
          end

          context "when persisting groups in a custom order" do
            let(:params) do
              {
                "questions" => [
                  {
                    "body" => { en: "Reordered" },
                    "description" => { en: "Desc" },
                    "question_type" => "multiple_option",
                    "grouped" => "1",
                    "groups" => {
                      "0" => { "id" => "ga", "title_en" => "Alpha", "position" => 1 },
                      "1" => { "id" => "gb", "title_en" => "Beta", "position" => 0 }
                    },
                    "response_options" => {
                      "0" => { "body" => { en: "A" }, "group_id" => "ga" },
                      "1" => { "body" => { en: "B" }, "group_id" => "gb" }
                    }
                  }
                ]
              }
            end

            let(:form) { QuestionsForm.from_params(params).with_context(context_params) }
            let(:command) { described_class.new(form, election) }

            it "preserves the submitted positions in settings[groups]" do
              command.call
              new_question = election.reload.questions.order(:position).last
              ordered = new_question.settings["groups"].sort_by { |g| g["position"] }
              expect(ordered.map { |g| g["title"]["en"] }).to eq(%w(Beta Alpha))
            end
          end

          context "when toggling an existing grouped question back to flat" do
            let!(:grouped_question) do
              create(:election_question,
                     election:,
                     question_type: "multiple_option",
                     settings: {
                       "grouped" => true,
                       "groups" => [{ "id" => "g1aaaaaa", "title" => { "en" => "G" }, "position" => 0 }]
                     }).tap do |q|
                create(:election_response_option, question: q, group_id: "g1aaaaaa", body: { en: "Opt" })
              end
            end

            let(:params) do
              {
                "questions" => [
                  {
                    "id" => grouped_question.id,
                    "body" => grouped_question.body,
                    "description" => grouped_question.description,
                    "question_type" => "multiple_option",
                    "grouped" => "0",
                    "response_options" => [
                      { "id" => grouped_question.response_options.first.id,
                        "body" => grouped_question.response_options.first.body,
                        "group_id" => "g1aaaaaa" }
                    ]
                  }
                ]
              }
            end

            let(:form) { QuestionsForm.from_params(params).with_context(context_params) }
            let(:command) { described_class.new(form, election) }

            it "clears grouped flag in settings" do
              command.call
              expect(grouped_question.reload.settings["grouped"]).to be false
            end

            it "empties settings[groups]" do
              command.call
              expect(grouped_question.reload.settings["groups"]).to eq([])
            end

            it "nullifies group_id on existing options" do
              command.call
              expect(grouped_question.response_options.first.reload.group_id).to be_nil
            end
          end
        end

        describe "original behavior is preserved" do
          context "when updating body and description" do
            let(:params) do
              {
                "questions" => [
                  {
                    "id" => existing_question.id,
                    "body" => { en: "Updated body" },
                    "description" => { en: "Updated desc" },
                    "question_type" => existing_question.question_type,
                    "response_options" => [
                      { "id" => existing_option1.id, "body" => existing_option1.body },
                      { "id" => existing_option2.id, "body" => existing_option2.body }
                    ]
                  }
                ]
              }
            end

            let(:form) { QuestionsForm.from_params(params).with_context(context_params) }
            let(:command) { described_class.new(form, election) }

            it "updates body and description" do
              command.call
              reloaded = existing_question.reload
              expect(translated(reloaded.body)).to eq("Updated body")
              expect(translated(reloaded.description)).to eq("Updated desc")
            end
          end

          context "when the form is invalid" do
            let(:form) do
              double("Form", invalid?: true, current_user:, current_organization: organization, questions: [])
            end
            let(:command) { described_class.new(form, election) }

            it "broadcasts :invalid" do
              expect { command.call }.to broadcast(:invalid)
            end
          end
        end
      end
    end
  end
end
