# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module CustomCsvCensus
      describe ColumnAccessors do
        # Create a test class that includes the module
        let(:test_class) do
          Class.new do
            include ColumnAccessors
          end
        end
        let(:instance) { test_class.new }

        describe "#column_name" do
          context "with string keys" do
            it "returns name from hash" do
              col = { "name" => "TestColumn" }
              expect(instance.column_name(col)).to eq("TestColumn")
            end
          end

          context "with symbol keys" do
            it "returns name from hash" do
              col = { name: "TestColumn" }
              expect(instance.column_name(col)).to eq("TestColumn")
            end
          end

          context "with both keys present" do
            it "prefers string key" do
              col = { "name" => "StringName", :name => "SymbolName" }
              expect(instance.column_name(col)).to eq("StringName")
            end
          end

          context "with nil value" do
            it "returns nil" do
              col = { "name" => nil }
              expect(instance.column_name(col)).to be_nil
            end
          end
        end

        describe "#column_type" do
          context "with string keys" do
            it "returns column_type from hash" do
              col = { "column_type" => "number" }
              expect(instance.column_type(col)).to eq("number")
            end
          end

          context "with symbol keys" do
            it "returns column_type from hash" do
              col = { column_type: "date" }
              expect(instance.column_type(col)).to eq("date")
            end
          end

          context "when column_type is not present" do
            it "returns default 'free_text'" do
              col = { "name" => "Test" }
              expect(instance.column_type(col)).to eq("free_text")
            end
          end

          context "with both keys present" do
            it "prefers string key" do
              col = { "column_type" => "alphanumeric", :column_type => "number" }
              expect(instance.column_type(col)).to eq("alphanumeric")
            end
          end
        end

        describe "#normalize_column" do
          it "normalizes hash to string keys" do
            col = { name: "Test", column_type: "number" }
            result = instance.normalize_column(col)
            expect(result).to eq({ "name" => "Test", "column_type" => "number" })
          end

          it "strips whitespace from name" do
            col = { name: "  Test  ", column_type: "number" }
            result = instance.normalize_column(col)
            expect(result["name"]).to eq("Test")
          end

          it "uses default column_type when not present" do
            col = { name: "Test" }
            result = instance.normalize_column(col)
            expect(result["column_type"]).to eq("free_text")
          end

          it "preserves original column_type" do
            col = { "name" => "Test", "column_type" => "alphanumeric" }
            result = instance.normalize_column(col)
            expect(result["column_type"]).to eq("alphanumeric")
          end

          context "with nil name" do
            it "returns nil for name after strip" do
              col = { name: nil, column_type: "number" }
              result = instance.normalize_column(col)
              expect(result["name"]).to be_nil
            end
          end
        end

        describe "#normalize_columns" do
          context "with array of columns" do
            it "normalizes each column" do
              columns = [
                { name: "First", column_type: "text_trim" },
                { "name" => "Second", "column_type" => "number" }
              ]
              result = instance.normalize_columns(columns)

              expect(result).to eq([
                                     { "name" => "First", "column_type" => "text_trim" },
                                     { "name" => "Second", "column_type" => "number" }
                                   ])
            end
          end

          context "with empty array" do
            it "returns empty array" do
              expect(instance.normalize_columns([])).to eq([])
            end
          end

          context "with nil" do
            it "returns empty array" do
              expect(instance.normalize_columns(nil)).to eq([])
            end
          end

          context "with non-hash elements" do
            it "filters out non-hash elements" do
              expect(instance.normalize_columns([""])).to eq([])
            end
          end

          context "with mixed key types" do
            it "normalizes all columns consistently" do
              columns = [
                { name: "A" },
                { "name" => "B", "column_type" => "date" },
                { :name => "C", :column_type => "number" }
              ]
              result = instance.normalize_columns(columns)

              expect(result.all? { |c| c.keys.all? { |k| k.is_a?(String) } }).to be(true)
            end
          end
        end
      end
    end
  end
end
