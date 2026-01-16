# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module CustomCsvCensus
      describe Data do
        subject { described_class.new(file, columns) }

        let(:columns) { [{ "name" => "Name", "column_type" => "free_text" }, { "name" => "ID", "column_type" => "alphanumeric" }] }

        def fixture_path(filename)
          File.join(ENV.fetch("ENGINE_ROOT"), "spec", "fixtures", "files", filename)
        end

        def create_temp_csv(content)
          file = Tempfile.new(%w(test .csv))
          file.write(content)
          file.rewind
          file
        end

        describe "#data" do
          context "when file is blank" do
            let(:file) { nil }

            it "returns empty array" do
              expect(subject.data).to eq([])
            end

            it "is not valid" do
              subject.data
              expect(subject.valid?).to be(false)
            end
          end

          context "when file is valid" do
            let(:file) { fixture_path("valid_census.csv") }

            it "returns parsed data" do
              expect(subject.data).to be_an(Array)
              expect(subject.data.length).to eq(2)
            end

            it "is valid" do
              expect(subject.valid?).to be(true)
            end

            it "preserves column names from config" do
              row = subject.data.first
              expect(row.keys).to eq(%w(Name ID))
            end
          end

          context "when file is malformed" do
            let(:file) { fixture_path("malformed.csv") }

            it "returns empty array" do
              expect(subject.data).to eq([])
            end

            it "is not valid" do
              expect(subject.valid?).to be(false)
            end

            it "has csv_error in errors" do
              subject.data
              expect(subject.errors.any? { |e| e[:type] == :csv_error }).to be(true)
            end
          end

          context "when CSV has wrong columns" do
            let(:file) { fixture_path("wrong_columns.csv") }

            it "returns empty array" do
              expect(subject.data).to eq([])
            end

            it "is not valid" do
              expect(subject.valid?).to be(false)
            end

            it "has header_error for extra columns" do
              subject.data
              expect(subject.errors.any? { |e| e[:type] == :header_error && e[:error] == :extra_columns }).to be(true)
            end
          end

          context "when CSV has missing columns" do
            let(:file) { create_temp_csv("Name\nJohn") }

            it "returns empty array" do
              expect(subject.data).to eq([])
            end

            it "has header_error for missing columns" do
              subject.data
              expect(subject.errors.any? { |e| e[:type] == :header_error && e[:error] == :missing_columns }).to be(true)
            end
          end
        end

        describe "header validation" do
          context "when headers match columns (case insensitive)" do
            let(:file) { create_temp_csv("name;id\nJohn;123") }

            it "accepts lowercase headers" do
              expect(subject.valid?).to be(true)
            end
          end

          context "when headers have extra whitespace" do
            let(:file) { create_temp_csv(" Name ; ID \nJohn;123") }

            it "normalizes headers and accepts them" do
              expect(subject.valid?).to be(true)
            end
          end

          context "when columns are empty" do
            let(:columns) { [] }
            let(:file) { create_temp_csv("Name;ID\nJohn;123") }

            it "skips header validation" do
              expect(subject.valid?).to be(true)
            end
          end
        end

        describe "row validation" do
          context "when row has invalid value for column type" do
            let(:columns) { [{ "name" => "Name", "column_type" => "free_text" }, { "name" => "ID", "column_type" => "number" }] }
            let(:file) { create_temp_csv("Name;ID\nJohn;abc") }

            it "is not valid" do
              expect(subject.valid?).to be(false)
            end

            it "has validation_error" do
              subject.data
              expect(subject.errors.any? { |e| e[:type] == :validation_error }).to be(true)
            end

            it "includes row number in error" do
              subject.data
              error = subject.errors.find { |e| e[:type] == :validation_error }
              expect(error[:row]).to eq(2)
            end
          end

          context "when all rows are valid" do
            let(:columns) { [{ "name" => "Name", "column_type" => "free_text" }, { "name" => "ID", "column_type" => "number" }] }
            let(:file) { create_temp_csv("Name;ID\nJohn;123\nJane;456") }

            it "is valid" do
              expect(subject.valid?).to be(true)
            end

            it "returns all rows" do
              expect(subject.data.length).to eq(2)
            end
          end

          context "when some rows are invalid" do
            let(:columns) { [{ "name" => "Name", "column_type" => "free_text" }, { "name" => "ID", "column_type" => "number" }] }
            let(:file) { create_temp_csv("Name;ID\nJohn;123\nJane;abc\nBob;789") }

            it "is not valid" do
              expect(subject.valid?).to be(false)
            end

            it "records error for invalid row" do
              subject.data
              error = subject.errors.find { |e| e[:type] == :validation_error }
              expect(error[:row]).to eq(3)
            end
          end

          context "when value is blank" do
            let(:columns) { [{ "name" => "Name", "column_type" => "free_text" }, { "name" => "ID", "column_type" => "number" }] }
            let(:file) { create_temp_csv("Name;ID\nJohn;\nJane;456") }

            it "skips validation for blank values" do
              expect(subject.valid?).to be(true)
            end
          end
        end

        describe "transformation" do
          context "when alphanumeric column" do
            let(:columns) { [{ "name" => "ID", "column_type" => "alphanumeric" }] }
            let(:file) { create_temp_csv("ID\nA-B-C-1-2-3") }

            it "removes non-alphanumeric characters" do
              expect(subject.data.first["ID"]).to eq("ABC123")
            end
          end

          context "when text_trim column" do
            let(:columns) { [{ "name" => "Name", "column_type" => "text_trim" }] }
            let(:file) { create_temp_csv("Name\n  John Doe  ") }

            it "trims whitespace" do
              expect(subject.data.first["Name"]).to eq("John Doe")
            end
          end

          context "when free_text column" do
            let(:columns) { [{ "name" => "Name", "column_type" => "free_text" }] }
            let(:file) { create_temp_csv("Name\n  John Doe  ") }

            it "preserves value unchanged" do
              expect(subject.data.first["Name"]).to eq("  John Doe  ")
            end
          end
        end

        describe "deduplication" do
          context "when CSV has duplicate rows" do
            let(:file) { create_temp_csv("Name;ID\nJohn;123\nJohn;123\nJane;456") }

            it "removes duplicates" do
              expect(subject.data.length).to eq(2)
            end

            it "tracks duplicates removed count" do
              subject.data
              expect(subject.duplicates_removed).to eq(1)
            end
          end

          context "when no duplicates" do
            let(:file) { create_temp_csv("Name;ID\nJohn;123\nJane;456") }

            it "keeps all rows" do
              expect(subject.data.length).to eq(2)
            end

            it "duplicates_removed is zero" do
              subject.data
              expect(subject.duplicates_removed).to eq(0)
            end
          end

          context "when duplicates after transformation" do
            let(:columns) { [{ "name" => "ID", "column_type" => "alphanumeric" }] }
            let(:file) { create_temp_csv("ID\nA-B-C\nABC") }

            it "removes rows that become duplicates after transformation" do
              expect(subject.data.length).to eq(1)
            end

            it "tracks duplicates removed" do
              subject.data
              expect(subject.duplicates_removed).to eq(1)
            end
          end
        end

        describe "#column_names" do
          let(:file) { nil }

          it "returns list of column names" do
            expect(subject.column_names).to eq(%w(Name ID))
          end

          context "when columns have symbol keys" do
            let(:columns) { [{ name: "First", column_type: "free_text" }, { name: "Second", column_type: "number" }] }

            it "returns normalized column names" do
              expect(subject.column_names).to eq(%w(First Second))
            end
          end
        end

        describe "#headers" do
          context "when file is parsed" do
            let(:file) { create_temp_csv("Name;ID\nJohn;123") }

            it "returns parsed headers" do
              subject.data
              expect(subject.headers).to eq(%w(Name ID))
            end
          end

          context "when file is malformed" do
            let(:file) { fixture_path("malformed.csv") }

            it "returns empty headers" do
              subject.data
              expect(subject.headers).to eq([])
            end
          end
        end

        describe "#error_messages" do
          context "when there are errors" do
            let(:file) { fixture_path("wrong_columns.csv") }

            it "returns human-readable error messages" do
              subject.data
              expect(subject.error_messages).to be_an(Array)
              expect(subject.error_messages).not_to be_empty
            end
          end

          context "when no errors" do
            let(:file) { fixture_path("valid_census.csv") }

            it "returns empty array" do
              subject.data
              expect(subject.error_messages).to eq([])
            end
          end
        end

        describe "data caching" do
          let(:file) { fixture_path("valid_census.csv") }

          it "caches result of process" do
            first_call = subject.data
            second_call = subject.data
            expect(first_call).to equal(second_call)
          end
        end
      end
    end
  end
end
