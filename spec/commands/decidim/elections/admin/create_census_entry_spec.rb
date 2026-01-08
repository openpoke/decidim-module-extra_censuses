# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      describe CreateCensusEntry do
        subject { described_class.new(form, election, current_user) }

        let(:organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:elections_component, participatory_space: participatory_process) }
        let(:current_user) { create(:user, :admin, :confirmed, organization:) }
        let(:election) do
          create(:election, component:, census_manifest: "custom_csv", census_settings: {
                   "columns" => [
                     { "name" => "dni", "column_type" => "alphanumeric" },
                     { "name" => "birth_date", "column_type" => "date" }
                   ]
                 })
        end
        let(:form) do
          CensusUpdateForm.from_params(data: { dni: "12345678A", birth_date: "1990-01-15" }).with_context(election:)
        end

        describe "when form is valid" do
          it "broadcasts :ok" do
            expect { subject.call }.to broadcast(:ok)
          end

          it "creates a new voter" do
            expect { subject.call }.to change(Decidim::Elections::Voter, :count).by(1)
          end

          it "saves voter with correct data" do
            subject.call
            voter = Decidim::Elections::Voter.last

            expect(voter.election).to eq(election)
            expect(voter.data["dni"]).to eq("12345678A")
            expect(voter.data["birth_date"]).to eq("1990-01-15")
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:create!)
              .with(
                Decidim::Elections::Voter,
                current_user,
                hash_including(election:, data: kind_of(Hash))
              )
              .and_call_original

            subject.call
          end

          context "when data needs transformation" do
            let(:form) do
              CensusUpdateForm.from_params(data: { dni: "12-345-678-A", birth_date: "1990-01-15" }).with_context(election:)
            end

            it "saves transformed data" do
              subject.call
              voter = Decidim::Elections::Voter.last

              expect(voter.data["dni"]).to eq("12345678A")
            end
          end
        end

        describe "when form is invalid" do
          let(:form) do
            CensusUpdateForm.from_params(data: { dni: "", birth_date: "" }).with_context(election:)
          end

          it "broadcasts :invalid" do
            expect { subject.call }.to broadcast(:invalid)
          end

          it "does not create a voter" do
            expect { subject.call }.not_to change(Decidim::Elections::Voter, :count)
          end
        end

        describe "when voter already exists" do
          before do
            create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" })
          end

          it "broadcasts :invalid" do
            expect { subject.call }.to broadcast(:invalid)
          end

          it "does not create a duplicate voter" do
            expect { subject.call }.not_to change(Decidim::Elections::Voter, :count)
          end
        end
      end
    end
  end
end
