# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      describe UpdateResponseOptionLabel do
        subject { described_class.new(form, response_option) }

        let(:organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:elections_component, participatory_space: participatory_process) }
        let(:current_user) { create(:user, :admin, :confirmed, organization:) }
        let(:election) { create(:election, component:) }
        let(:question) { create(:election_question, election:) }
        let(:response_option) { create(:election_response_option, question:) }
        let(:attributes) { { title_en: "Winner", description_en: "The winning option", position: 2, color: "blue" } }
        let(:form) { ResponseOptionLabelForm.from_params(response_option_label: attributes).with_context(current_user:, current_organization: organization) }

        describe "when the form is valid" do
          it "broadcasts :ok" do
            expect { subject.call }.to broadcast(:ok)
          end

          it "persists the label into settings" do
            subject.call
            label = response_option.reload.settings["label"]
            expect(label["title"]).to eq("en" => "Winner")
            expect(label["description"]).to eq("en" => "The winning option")
            expect(label["position"]).to eq(2)
            expect(label["color"]).to eq("blue")
          end

          it "preserves other settings keys" do
            response_option.update!(settings: { "foo" => "bar" })
            subject.call
            expect(response_option.reload.settings["foo"]).to eq("bar")
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:update!)
              .with(response_option, current_user, kind_of(Hash))
              .and_call_original

            subject.call
          end
        end

        describe "when the form is invalid" do
          let(:attributes) { { title_en: "", description_en: "", position: 1, color: "blue" } }

          it "broadcasts :invalid" do
            expect { subject.call }.to broadcast(:invalid)
          end

          it "does not change settings" do
            expect { subject.call }.not_to(change { response_option.reload.settings })
          end
        end
      end
    end
  end
end
