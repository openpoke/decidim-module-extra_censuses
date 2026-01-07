# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Censuses
      describe CustomCsvForm do
        subject { described_class.new(attributes).with_context(context) }

        let(:organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:elections_component, participatory_space: participatory_process) }
        let(:election) do
          create(:election, component:, census_manifest: "custom_csv", census_settings: {
                   "columns" => [
                     { "name" => "Name", "column_type" => "text_trim" },
                     { "name" => "ID", "column_type" => "alphanumeric" }
                   ]
                 })
        end
        let(:context) { { election: } }
        let(:attributes) { { census_data: { "Name" => "John", "ID" => "ABC-123" } } }

        let!(:voter) do
          create(:election_voter, election:, data: { "Name" => "John", "ID" => "ABC123" })
        end

        describe "validation" do
          context "when voter exists with matching data" do
            it { is_expected.to be_valid }
          end

          context "when voter does not exist" do
            let(:attributes) { { census_data: { "Name" => "Unknown", "ID" => "999" } } }

            it { is_expected.not_to be_valid }
          end

          context "when census data is empty" do
            let(:attributes) { { census_data: {} } }

            it { is_expected.not_to be_valid }
          end
        end

        describe "#voter_uid" do
          it "returns voter global id" do
            expect(subject.voter_uid).to eq(voter.to_global_id.to_s)
          end

          context "when voter does not exist" do
            let(:attributes) { { census_data: { "Name" => "Unknown", "ID" => "999" } } }

            it "returns nil" do
              expect(subject.voter_uid).to be_nil
            end
          end
        end

        describe "#census_user" do
          it "finds voter with transformed data" do
            expect(subject.census_user).to eq(voter)
          end

          context "when alphanumeric transformation is applied" do
            let(:attributes) { { census_data: { "Name" => "John", "ID" => "A-B-C-1-2-3" } } }

            it "finds voter after removing non-alphanumeric characters" do
              expect(subject.census_user).to eq(voter)
            end
          end

          context "when text_trim transformation is applied" do
            let(:attributes) { { census_data: { "Name" => "  John  ", "ID" => "ABC123" } } }

            it "finds voter after trimming spaces" do
              expect(subject.census_user).to eq(voter)
            end
          end
        end

        describe "#column_names" do
          it "returns column names from settings" do
            expect(subject.column_names).to eq(%w[Name ID])
          end

          context "when election has no columns in census_settings" do
            let(:election) { create(:election, component:, census_manifest: "custom_csv", census_settings: {}) }

            it "returns empty array" do
              expect(subject.column_names).to eq([])
            end
          end
        end

        describe "#column_definitions" do
          it "returns column definitions from settings" do
            expect(subject.column_definitions).to eq([
                                                       { "name" => "Name", "column_type" => "text_trim" },
                                                       { "name" => "ID", "column_type" => "alphanumeric" }
                                                     ])
          end
        end
      end
    end
  end
end
