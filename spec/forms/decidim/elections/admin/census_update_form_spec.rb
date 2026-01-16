# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      describe CensusUpdateForm do
        subject { described_class.from_params(params).with_context(election:) }

        let(:organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:elections_component, participatory_space: participatory_process) }
        let(:election) do
          create(:election, component:, census_manifest: "custom_csv", census_settings: {
                   "columns" => [
                     { "name" => "dni", "column_type" => "alphanumeric" },
                     { "name" => "birth_date", "column_type" => "date" }
                   ]
                 })
        end
        let(:params) { { data: { dni: "12345678A", birth_date: "1990-01-15" } } }

        describe "validation" do
          describe "all_columns_present" do
            context "when all columns are filled" do
              it { is_expected.to be_valid }
            end

            context "when one column is empty" do
              let(:params) { { data: { dni: "12345678A", birth_date: "" } } }

              it { is_expected.not_to be_valid }

              it "adds error with column name" do
                subject.valid?
                expect(subject.errors[:data].to_s).to include("birth_date")
              end
            end

            context "when all columns are empty" do
              let(:params) { { data: { dni: "", birth_date: "" } } }

              it { is_expected.not_to be_valid }

              it "adds errors for each column" do
                subject.valid?
                expect(subject.errors[:data].to_s).to include("dni")
                expect(subject.errors[:data].to_s).to include("birth_date")
              end
            end

            context "when data is nil" do
              let(:params) { { data: nil } }

              it { is_expected.not_to be_valid }
            end
          end

          describe "voter_not_exists" do
            context "when voter with these data does not exist" do
              it { is_expected.to be_valid }
            end

            context "when voter with these data already exists" do
              before do
                create(:election_voter, election:, data: { "dni" => "12345678A", "birth_date" => "1990-01-15" })
              end

              it { is_expected.not_to be_valid }

              it "adds already_exists error" do
                subject.valid?
                expect(subject.errors[:base].to_s).to include("already exists")
              end
            end

            context "when voter exists with different data" do
              before do
                create(:election_voter, election:, data: { "dni" => "87654321B", "birth_date" => "1985-05-20" })
              end

              it { is_expected.to be_valid }
            end
          end
        end

        describe "#transformed_data" do
          context "when alphanumeric type" do
            let(:params) { { data: { dni: "12-345-678-A", birth_date: "1990-01-15" } } }

            it "removes non-alphanumeric characters" do
              expect(subject.transformed_data["dni"]).to eq("12345678A")
            end
          end

          context "when date type" do
            let(:params) { { data: { dni: "12345678A", birth_date: "1990-01-15" } } }

            it "preserves date format" do
              expect(subject.transformed_data["birth_date"]).to eq("1990-01-15")
            end
          end

          context "when text_trim type" do
            let(:election) do
              create(:election, component:, census_manifest: "custom_csv", census_settings: {
                       "columns" => [
                         { "name" => "name", "column_type" => "text_trim" }
                       ]
                     })
            end
            let(:params) { { data: { name: "  John Doe  " } } }

            it "trims spaces" do
              expect(subject.transformed_data["name"]).to eq("John Doe")
            end
          end

          context "when number type" do
            let(:election) do
              create(:election, component:, census_manifest: "custom_csv", census_settings: {
                       "columns" => [
                         { "name" => "phone", "column_type" => "number" }
                       ]
                     })
            end
            let(:params) { { data: { phone: "123456789" } } }

            it "keeps only digits" do
              expect(subject.transformed_data["phone"]).to eq("123456789")
            end
          end

          context "when free_text type" do
            let(:election) do
              create(:election, component:, census_manifest: "custom_csv", census_settings: {
                       "columns" => [
                         { "name" => "notes", "column_type" => "free_text" }
                       ]
                     })
            end
            let(:params) { { data: { notes: "  Some text here!  " } } }

            it "does not modify value" do
              expect(subject.transformed_data["notes"]).to eq("  Some text here!  ")
            end
          end

          context "when value is blank" do
            let(:params) { { data: { dni: "", birth_date: "1990-01-15" } } }

            it "skips blank values" do
              expect(subject.transformed_data).not_to have_key("dni")
              expect(subject.transformed_data).to have_key("birth_date")
            end
          end
        end

        describe "#column_definitions" do
          it "returns columns from election.census_settings" do
            expect(subject.column_definitions).to eq([
                                                       { "name" => "dni", "column_type" => "alphanumeric" },
                                                       { "name" => "birth_date", "column_type" => "date" }
                                                     ])
          end

          context "when election has no census_settings" do
            let(:election) { create(:election, component:, census_manifest: "custom_csv", census_settings: {}) }

            it "returns empty array" do
              expect(subject.column_definitions).to eq([])
            end
          end

          context "when election census_settings has no columns key" do
            let(:election) { create(:election, component:, census_manifest: "custom_csv", census_settings: { "other" => "data" }) }

            it "returns empty array" do
              expect(subject.column_definitions).to eq([])
            end
          end
        end
      end
    end
  end
end
