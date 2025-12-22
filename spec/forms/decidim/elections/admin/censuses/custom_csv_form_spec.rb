# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      module Censuses
        describe CustomCsvForm do
          subject { described_class.new(attributes).with_context(context) }

          let(:organization) { create(:organization) }
          let(:participatory_process) { create(:participatory_process, organization:) }
          let(:component) { create(:elections_component, participatory_space: participatory_process) }
          let(:election) { create(:election, component:) }
          let(:context) { { current_organization: organization, election: } }
          let(:attributes) { {} }

          def fixture_path(filename)
            File.join(ENV.fetch("ENGINE_ROOT"), "spec", "fixtures", "files", filename)
          end

          describe "columns validation" do
            context "when columns are valid" do
              let(:attributes) do
                {
                  columns: [
                    { name: "Name", column_type: "free_text" },
                    { name: "ID", column_type: "alphanumeric" }
                  ]
                }
              end

              it { is_expected.to be_valid }
            end

            context "when column name is blank" do
              let(:attributes) do
                {
                  columns: [
                    { name: "", column_type: "free_text" }
                  ]
                }
              end

              it { is_expected.not_to be_valid }

              it "adds error to columns" do
                subject.valid?
                expect(subject.errors[:columns]).not_to be_empty
              end
            end

            context "when column type is invalid" do
              let(:attributes) do
                {
                  columns: [
                    { name: "Name", column_type: "invalid_type" }
                  ]
                }
              end

              it { is_expected.not_to be_valid }

              it "adds error to columns" do
                subject.valid?
                expect(subject.errors[:columns]).not_to be_empty
              end
            end
          end

          describe "file validation" do
            context "when file is uploaded without configured columns" do
              let(:attributes) { { file: upload_test_file(fixture_path("valid_census.csv"), content_type: "text/csv") } }

              it { is_expected.not_to be_valid }

              it "adds columns_not_configured error" do
                subject.valid?
                expect(subject.errors[:file]).to include(match(/columns/i))
              end
            end

            context "when file is malformed CSV" do
              let(:election) { create(:election, component:, census_settings: { "columns" => [{ "name" => "Name", "column_type" => "free_text" }, { "name" => "ID", "column_type" => "alphanumeric" }] }) }
              let(:attributes) { { file: upload_test_file(fixture_path("malformed.csv"), content_type: "text/csv") } }

              it { is_expected.not_to be_valid }
            end

            context "when file has wrong number of columns" do
              let(:election) { create(:election, component:, census_settings: { "columns" => [{ "name" => "Name", "column_type" => "free_text" }, { "name" => "ID", "column_type" => "alphanumeric" }] }) }
              let(:attributes) { { file: upload_test_file(fixture_path("wrong_columns.csv"), content_type: "text/csv") } }

              it { is_expected.not_to be_valid }
            end

            context "when file is valid" do
              let(:election) { create(:election, component:, census_settings: { "columns" => [{ "name" => "Name", "column_type" => "free_text" }, { "name" => "ID", "column_type" => "alphanumeric" }] }) }
              let(:attributes) { { file: upload_test_file(fixture_path("valid_census.csv"), content_type: "text/csv") } }

              it { is_expected.to be_valid }
            end
          end

          describe "#effective_columns" do
            context "when columns are submitted" do
              let(:attributes) { { columns: [{ name: "Name", column_type: "free_text" }] } }

              it "returns submitted columns" do
                expect(subject.effective_columns).to eq(attributes[:columns])
              end
            end

            context "when columns are not submitted but persisted" do
              let(:election) { create(:election, component:, census_settings: { "columns" => [{ "name" => "ID", "column_type" => "number" }] }) }

              it "returns persisted columns" do
                expect(subject.effective_columns).to eq([{ "name" => "ID", "column_type" => "number" }])
              end
            end
          end

          describe "#census_settings" do
            context "when columns are submitted" do
              let(:attributes) { { columns: [{ name: "Name", column_type: "free_text" }] } }

              it "returns normalized columns" do
                expect(subject.census_settings).to eq({ "columns" => [{ "name" => "Name", "column_type" => "free_text" }] })
              end
            end

            context "when columns are not submitted" do
              let(:election) { create(:election, component:, census_settings: { "columns" => [{ "name" => "ID", "column_type" => "number" }] }) }

              it "returns persisted columns" do
                expect(subject.census_settings).to eq({ "columns" => [{ "name" => "ID", "column_type" => "number" }] })
              end
            end
          end

          describe "voters exist validation" do
            let(:election) { create(:election, component:) }

            before do
              create(:election_voter, election:)
            end

            context "when uploading file with existing voters" do
              let(:attributes) { { file: upload_test_file(fixture_path("valid_census.csv"), content_type: "text/csv") } }

              it { is_expected.not_to be_valid }

              it "adds voters_exist error" do
                subject.valid?
                expect(subject.errors[:file]).not_to be_empty
              end
            end

            context "when remove_all is true" do
              let(:attributes) { { file: upload_test_file(fixture_path("valid_census.csv"), content_type: "text/csv"), remove_all: true } }

              it "allows file upload" do
                subject.valid?
                expect(subject.errors[:file]).not_to include(match(/voters/i))
              end
            end
          end
        end
      end
    end
  end
end
