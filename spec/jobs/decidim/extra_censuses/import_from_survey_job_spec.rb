# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe ImportFromSurveyJob do
      subject { described_class }

      let(:organization) { create(:organization) }
      let(:participatory_process) { create(:participatory_process, organization:) }
      let(:elections_component) { create(:elections_component, participatory_space: participatory_process) }
      let(:census_columns) { [{ "name" => "dni", "column_type" => "alphanumeric" }, { "name" => "birth_date", "column_type" => "date" }] }
      let(:election) { create(:election, component: elections_component, census_manifest: "custom_csv", census_settings: { "columns" => census_columns }) }
      let(:census_data_list) { [{ "dni" => "12345678A", "birth_date" => "1990-01-15" }, { "dni" => "87654321B", "birth_date" => "1985-05-20" }] }

      describe "#perform" do
        it "creates voters for each census data entry" do
          expect do
            subject.perform_now(election.id, census_data_list)
          end.to change(Decidim::Elections::Voter, :count).by(2)
        end

        it "creates voters with correct data" do
          subject.perform_now(election.id, census_data_list)

          voter = election.voters.find_by("data->>'dni' = ?", "12345678A")
          expect(voter).to be_present
          expect(voter.data["birth_date"]).to eq("1990-01-15")
        end

        it "associates voters with the election" do
          subject.perform_now(election.id, census_data_list)

          expect(election.voters.count).to eq(2)
        end

        context "when census_data_list is empty" do
          let(:census_data_list) { [] }

          it "does not create any voters" do
            expect do
              subject.perform_now(election.id, census_data_list)
            end.not_to change(Decidim::Elections::Voter, :count)
          end
        end

        context "when voter with same data already exists" do
          before { create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" }) }

          it "skips duplicate and creates only non-duplicate" do
            expect do
              subject.perform_now(election.id, census_data_list)
            end.to change(Decidim::Elections::Voter, :count).by(1)
          end

          it "creates the non-duplicate voter" do
            subject.perform_now(election.id, census_data_list)

            voter = election.voters.find_by("data->>'dni' = ?", "87654321B")
            expect(voter).to be_present
          end
        end

        context "when all voters already exist" do
          before do
            create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" })
            create(:election_voter, election:, data: { "dni" => "87654321B", "birth_date" => "1985-05-20" })
          end

          it "does not create any new voters" do
            expect do
              subject.perform_now(election.id, census_data_list)
            end.not_to change(Decidim::Elections::Voter, :count)
          end
        end

        context "when election does not exist" do
          it "raises ActiveRecord::RecordNotFound" do
            expect do
              subject.perform_now(999_999, census_data_list)
            end.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        it "wraps creation in transaction" do
          allow(Decidim::Elections::Voter).to receive(:create!).and_call_original
          allow(Decidim::Elections::Voter).to receive(:create!).with(
            election: election,
            data: { "dni" => "87654321B", "birth_date" => "1985-05-20" }
          ).and_raise(ActiveRecord::RecordInvalid)

          expect do
            subject.perform_now(election.id, census_data_list)
          end.to raise_error(ActiveRecord::RecordInvalid)

          expect(election.voters.count).to eq(0)
        end
      end
    end
  end
end
