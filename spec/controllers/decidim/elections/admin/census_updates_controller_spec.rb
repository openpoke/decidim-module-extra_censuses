# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      describe CensusUpdatesController do
        let(:component) { create(:elections_component) }
        let(:organization) { component.organization }
        let(:current_user) { create(:user, :admin, :confirmed, organization:) }
        let(:census_columns) { [{ "name" => "dni", "column_type" => "alphanumeric" }, { "name" => "birth_date", "column_type" => "date" }] }
        let(:election) { create(:election, component:, census_manifest: "custom_csv", census_settings: { "columns" => census_columns }) }
        let(:election_census_updates_path) { Decidim::EngineRouter.admin_proxy(component).election_census_updates_path(election) }

        before do
          request.env["decidim.current_organization"] = organization
          request.env["decidim.current_participatory_space"] = component.participatory_space
          request.env["decidim.current_component"] = component
          allow(controller).to receive(:election_census_updates_path).with(election).and_return(election_census_updates_path)
          sign_in current_user
        end

        describe "GET index" do
          it "renders the index page" do
            get :index, params: { election_id: election.id }

            expect(response).to be_successful
            expect(response).to render_template(:index)
          end

          context "with search query" do
            let!(:voter1) { create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-01" }) }
            let!(:voter2) { create(:election_voter, election:, data: { "dni" => "87654321B", "birth_date" => "1985-05-15" }) }

            it "filters voters by identifier column" do
              get :index, params: { election_id: election.id, q: "12345" }

              expect(response).to be_successful
              expect(assigns(:voters)).to include(voter1)
              expect(assigns(:voters)).not_to include(voter2)
            end
          end
        end

        describe "GET new" do
          it "renders the new page" do
            get :new, params: { election_id: election.id }

            expect(response).to be_successful
            expect(response).to render_template(:new)
          end
        end

        describe "POST create" do
          context "with valid data" do
            let(:params) { { election_id: election.id, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" } } }

            it "creates a new voter and redirects with success message" do
              expect do
                post :create, params: params
              end.to change(Decidim::Elections::Voter, :count).by(1)

              expect(flash[:notice]).to eq(I18n.t("decidim.elections.admin.census_updates.create.success"))
              expect(response).to redirect_to(election_census_updates_path)
            end
          end

          context "with invalid data" do
            let(:params) { { election_id: election.id, data: { "dni" => "", "birth_date" => "" } } }

            it "renders the new view with error message" do
              post :create, params: params

              expect(flash[:alert]).to eq(I18n.t("decidim.elections.admin.census_updates.create.error"))
              expect(response).to render_template(:new)
            end
          end

          context "with duplicate data" do
            let!(:existing_voter) { create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" }) }
            let(:params) { { election_id: election.id, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" } } }

            it "renders the new view with error message" do
              post :create, params: params

              expect(flash[:alert]).to eq(I18n.t("decidim.elections.admin.census_updates.create.error"))
              expect(response).to render_template(:new)
            end
          end
        end

        describe "DELETE destroy" do
          let!(:voter) { create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" }) }

          it "destroys the voter and redirects with success message" do
            expect do
              delete :destroy, params: { election_id: election.id, id: voter.id }
            end.to change(Decidim::Elections::Voter, :count).by(-1)

            expect(flash[:notice]).to eq(I18n.t("decidim.elections.admin.census_updates.destroy.success"))
            expect(response).to redirect_to(election_census_updates_path)
          end
        end
      end
    end
  end
end
