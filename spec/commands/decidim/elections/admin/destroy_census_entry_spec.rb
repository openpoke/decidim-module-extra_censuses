# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      describe DestroyCensusEntry do
        subject { described_class.new(voter, current_user) }

        let(:organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:elections_component, participatory_space: participatory_process) }
        let(:current_user) { create(:user, :admin, :confirmed, organization:) }
        let(:election) do
          create(:election, component:, census_manifest: "custom_csv", census_settings: {
                   "columns" => [
                     { "name" => "dni", "column_type" => "alphanumeric" }
                   ]
                 })
        end
        let!(:voter) { create(:election_voter, election:, data: { "dni" => "12345678A" }) }

        describe "#call" do
          it "broadcasts :ok" do
            expect { subject.call }.to broadcast(:ok)
          end

          it "destroys the voter" do
            expect { subject.call }.to change(Decidim::Elections::Voter, :count).by(-1)
          end

          it "removes the specific voter" do
            subject.call
            expect(Decidim::Elections::Voter.find_by(id: voter.id)).to be_nil
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with(:delete, voter, current_user)
              .and_call_original

            subject.call
          end
        end

        describe "when multiple voters exist" do
          let!(:other_voter) { create(:election_voter, election:, data: { "dni" => "87654321B" }) }

          it "only destroys the specified voter" do
            subject.call
            expect(Decidim::Elections::Voter.find_by(id: voter.id)).to be_nil
            expect(Decidim::Elections::Voter.find_by(id: other_voter.id)).to eq(other_voter)
          end
        end
      end
    end
  end
end
