# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    describe VotesController do
      let(:user) { create(:user, :confirmed, organization: component.organization) }
      let(:component) { create(:elections_component) }
      let(:election) { create(:election, :published, :with_internal_users_census, :ongoing, component:) }
      let!(:question) do
        create(:election_question, :voting_enabled,
               election:,
               question_type: "multiple_option",
               min_choices:,
               max_choices:)
      end
      let!(:response_options) do
        create_list(:election_response_option, 5, question:)
      end
      let(:min_choices) { nil }
      let(:max_choices) { nil }

      let(:params) do
        { component_id: component.id, election_id: election.id, id: question.id }
      end
      let(:election_vote_path) { Decidim::EngineRouter.main_proxy(component).election_vote_path(election_id: election.id, id: question.id) }
      let(:confirm_election_votes_path) { Decidim::EngineRouter.main_proxy(component).confirm_election_votes_path(election_id: election.id) }

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
        allow(controller).to receive(:current_participatory_space).and_return(component.participatory_space)
        allow(controller).to receive(:current_component).and_return(component)
        allow(controller).to receive(:election_vote_path).and_return(election_vote_path)
        allow(controller).to receive(:confirm_election_votes_path).and_return(confirm_election_votes_path)
        sign_in user
      end

      describe "PATCH update" do
        context "with no min_choices/max_choices set" do
          it "saves the vote to the buffer and redirects to the confirm page" do
            patch :update, params: params.merge(
              response: { question.id.to_s => [response_options.first.id] }
            )

            expect(session[:votes_buffer][question.id.to_s]).to eq([response_options.first.id.to_s])
            expect(response).to redirect_to(confirm_election_votes_path)
          end

          it "allows an empty selection (no range enforcement)" do
            patch :update, params: params
            expect(response).to redirect_to(confirm_election_votes_path)
          end
        end

        context "with only max_choices set" do
          let(:max_choices) { 3 }

          it "rejects a selection above max_choices with a flash alert" do
            patch :update, params: params.merge(
              response: { question.id.to_s => response_options.first(4).map(&:id) }
            )

            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:show)
            expect(flash.now[:alert]).to match(/cannot select more than 3/)
          end

          it "accepts a selection equal to max_choices" do
            patch :update, params: params.merge(
              response: { question.id.to_s => response_options.first(3).map(&:id) }
            )

            expect(response).to redirect_to(confirm_election_votes_path)
          end

          it "accepts a selection below max_choices" do
            patch :update, params: params.merge(
              response: { question.id.to_s => [response_options.first.id] }
            )

            expect(response).to redirect_to(confirm_election_votes_path)
          end
        end

        context "with only min_choices set" do
          let(:min_choices) { 2 }

          it "rejects a selection below min_choices with a flash alert" do
            patch :update, params: params.merge(
              response: { question.id.to_s => [response_options.first.id] }
            )

            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:show)
            expect(flash.now[:alert]).to match(/at least 2/)
          end

          it "accepts a selection equal to min_choices" do
            patch :update, params: params.merge(
              response: { question.id.to_s => response_options.first(2).map(&:id) }
            )

            expect(response).to redirect_to(confirm_election_votes_path)
          end

          it "accepts a selection above min_choices" do
            patch :update, params: params.merge(
              response: { question.id.to_s => response_options.first(5).map(&:id) }
            )

            expect(response).to redirect_to(confirm_election_votes_path)
          end
        end

        context "with both min_choices and max_choices set" do
          let(:min_choices) { 2 }
          let(:max_choices) { 3 }

          it "rejects a selection below the range" do
            patch :update, params: params.merge(
              response: { question.id.to_s => [response_options.first.id] }
            )

            expect(response).to render_template(:show)
            expect(flash.now[:alert]).to match(/between 2 and 3/)
          end

          it "rejects a selection above the range" do
            patch :update, params: params.merge(
              response: { question.id.to_s => response_options.first(4).map(&:id) }
            )

            expect(response).to render_template(:show)
            expect(flash.now[:alert]).to match(/between 2 and 3/)
          end

          it "accepts a selection within the range" do
            patch :update, params: params.merge(
              response: { question.id.to_s => response_options.first(2).map(&:id) }
            )

            expect(response).to redirect_to(confirm_election_votes_path)
          end
        end
      end
    end
  end
end
