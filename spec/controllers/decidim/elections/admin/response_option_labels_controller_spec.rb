# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      describe ResponseOptionLabelsController do
        let(:component) { create(:elections_component) }
        let(:organization) { component.organization }
        let(:current_user) { create(:user, :admin, :confirmed, organization:) }
        let(:election) { create(:election, :published, :ongoing, component:) }
        let(:question) { create(:election_question, election:) }
        let(:response_option) { create(:election_response_option, question:) }
        let(:dashboard_path) { Decidim::EngineRouter.admin_proxy(component).dashboard_election_path(election) }
        let(:params) do
          {
            election_id: election.id,
            id: response_option.id,
            response_option_label: { title_en: "Winner", description_en: "Top option", position: 1, color: "green" }
          }
        end

        before do
          request.env["decidim.current_organization"] = organization
          request.env["decidim.current_participatory_space"] = component.participatory_space
          request.env["decidim.current_component"] = component
          allow(controller).to receive(:dashboard_election_path).with(election).and_return(dashboard_path)
        end

        describe "PUT update" do
          context "when the user is an admin" do
            before { sign_in current_user }

            it "saves the label even though the election is no longer editable" do
              expect(election.editable?).to be(false)

              put :update, params: params

              expect(flash[:notice]).to eq(I18n.t("decidim.elections.admin.response_option_labels.update.success"))
              expect(response).to redirect_to(dashboard_path)
              expect(response_option.reload.settings["label"]).to include("title" => { "en" => "Winner" }, "color" => "green")
            end
          end

          context "when the user is not an admin" do
            let(:current_user) { create(:user, :confirmed, organization:) }

            before { sign_in current_user }

            it "does not save the label" do
              expect { put :update, params: params }.not_to(change { response_option.reload.settings })
            end
          end

          context "when the results are published" do
            let(:election) { create(:election, :after_end, :published_results, component:) }

            before { sign_in current_user }

            it "does not save the label" do
              expect { put :update, params: params }.not_to(change { response_option.reload.settings })
            end
          end
        end
      end
    end
  end
end
