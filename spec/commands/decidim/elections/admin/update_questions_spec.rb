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
