# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module CustomCsvCensus
      describe CsvParser do
        def create_temp_csv(content)
          file = Tempfile.new(%w(test .csv))
          file.write(content)
          file.rewind
          file.path
        end

        def fixture_path(filename)
          File.join(ENV.fetch("ENGINE_ROOT"), "spec", "fixtures", "files", filename)
        end

        describe ".parse" do
          context "with valid CSV" do
            let(:file) { create_temp_csv("Name;ID\nJohn;123\nJane;456") }

            it "returns rows and headers" do
              rows, headers = described_class.parse(file)
              expect(rows).to be_an(Array)
              expect(headers).to be_an(Array)
            end

            it "parses rows correctly" do
              rows, _headers = described_class.parse(file)
              expect(rows.length).to eq(2)
              expect(rows.first["Name"]).to eq("John")
              expect(rows.first["ID"]).to eq("123")
            end

            it "extracts headers" do
              _rows, headers = described_class.parse(file)
              expect(headers).to eq(%w(Name ID))
            end
          end

          context "with semicolon separator" do
            let(:file) { create_temp_csv("Col1;Col2;Col3\na;b;c") }

            it "uses semicolon as column separator" do
              rows, headers = described_class.parse(file)
              expect(headers).to eq(%w(Col1 Col2 Col3))
              expect(rows.first["Col1"]).to eq("a")
              expect(rows.first["Col2"]).to eq("b")
              expect(rows.first["Col3"]).to eq("c")
            end
          end

          context "with whitespace in headers" do
            let(:file) { create_temp_csv(" Name ; ID \nJohn;123") }

            it "strips whitespace from headers" do
              _rows, headers = described_class.parse(file)
              expect(headers).to eq(%w(Name ID))
            end

            it "strips whitespace from row keys" do
              rows, _headers = described_class.parse(file)
              expect(rows.first.keys).to eq(%w(Name ID))
            end
          end

          context "with UTF-8 BOM" do
            let(:file) do
              bom = "\xEF\xBB\xBF"
              create_temp_csv("#{bom}Name;ID\nJohn;123")
            end

            it "handles UTF-8 BOM correctly" do
              _rows, headers = described_class.parse(file)
              expect(headers.first).to eq("Name")
            end
          end

          context "with empty file" do
            let(:file) { create_temp_csv("") }

            it "returns empty arrays" do
              rows, headers = described_class.parse(file)
              expect(rows).to eq([])
              expect(headers).to eq([])
            end
          end

          context "with headers only" do
            let(:file) { create_temp_csv("Name;ID\n") }

            it "returns empty rows" do
              rows, headers = described_class.parse(file)
              expect(rows).to eq([])
              expect(headers).to eq(%w(Name ID))
            end
          end

          context "with malformed CSV" do
            let(:file) { fixture_path("malformed.csv") }

            it "raises CSV::MalformedCSVError" do
              expect { described_class.parse(file) }.to raise_error(CSV::MalformedCSVError)
            end
          end

          context "with special characters in values" do
            let(:file) { create_temp_csv("Name;ID\n\"John, Jr.\";123") }

            it "handles quoted values with special characters" do
              rows, _headers = described_class.parse(file)
              expect(rows.first["Name"]).to eq("John, Jr.")
            end
          end

          context "with nil headers" do
            let(:file) { create_temp_csv(";Name;\nval1;val2;val3") }

            it "handles nil headers gracefully" do
              _rows, headers = described_class.parse(file)
              expect(headers).to include("Name")
            end
          end

          context "with multiple rows" do
            let(:file) { create_temp_csv("Name;ID\nAlice;1\nBob;2\nCharlie;3") }

            it "parses all rows" do
              rows, _headers = described_class.parse(file)
              expect(rows.length).to eq(3)
              expect(rows.map { |r| r["Name"] }).to eq(%w(Alice Bob Charlie))
            end
          end
        end
      end
    end
  end
end
