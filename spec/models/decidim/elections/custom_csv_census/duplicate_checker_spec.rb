# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module CustomCsvCensus
      describe DuplicateChecker do
        let(:organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:elections_component, participatory_space: participatory_process) }
        let(:election) { create(:election, component:) }

        describe ".exists?" do
          context "when census_data is blank" do
            it "returns false for nil" do
              expect(described_class.exists?(election, nil)).to be(false)
            end

            it "returns false for empty hash" do
              expect(described_class.exists?(election, {})).to be(false)
            end
          end

          context "when no voters exist" do
            it "returns false" do
              census_data = { "dni" => "12345678A", "birth_date" => "1990-01-15" }
              expect(described_class.exists?(election, census_data)).to be(false)
            end
          end

          context "when voter with exact matching data exists" do
            before do
              create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" })
            end

            it "returns true" do
              census_data = { "dni" => "12345678A", "birth_date" => "1990-01-15" }
              expect(described_class.exists?(election, census_data)).to be(true)
            end
          end

          context "when voter exists with partial matching data" do
            before do
              create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1985-05-20" })
            end

            it "returns false for different birth_date" do
              census_data = { "dni" => "12345678A", "birth_date" => "1990-01-15" }
              expect(described_class.exists?(election, census_data)).to be(false)
            end
          end

          context "when voter exists in different election" do
            let(:another_election) { create(:election, component:) }

            before do
              create(:election_voter, election: another_election, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" })
            end

            it "returns false" do
              census_data = { "dni" => "12345678A", "birth_date" => "1990-01-15" }
              expect(described_class.exists?(election, census_data)).to be(false)
            end
          end

          context "with string and symbol keys" do
            before do
              create(:election_voter, election:, data: { "dni" => "12345678A" })
            end

            it "matches with string keys" do
              expect(described_class.exists?(election, { "dni" => "12345678A" })).to be(true)
            end

            it "matches with symbol keys" do
              expect(described_class.exists?(election, { dni: "12345678A" })).to be(true)
            end
          end
        end
      end
    end
  end
end
