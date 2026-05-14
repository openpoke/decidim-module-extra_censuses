# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe ResponseOptionGroup do
      subject { described_class.new(id: "abc12345", title: { "en" => "My group" }, position: 2) }

      describe ".from_settings_hash" do
        it "builds a value object from a string-keyed hash" do
          built = described_class.from_settings_hash(
            "id" => "abc12345",
            "title" => { "en" => "My group" },
            "position" => 2
          )
          expect(built.id).to eq("abc12345")
          expect(built.title).to eq("en" => "My group")
          expect(built.position).to eq(2)
        end

        it "defaults position to 0 when missing" do
          built = described_class.from_settings_hash("id" => "abc12345", "title" => { "en" => "x" })
          expect(built.position).to eq(0)
        end

        it "ignores unknown keys" do
          expect do
            described_class.from_settings_hash(
              "id" => "abc12345",
              "title" => { "en" => "x" },
              "position" => 0,
              "extra" => "noise"
            )
          end.not_to raise_error
        end
      end

      describe "#to_h" do
        it "returns the value object as a symbol-keyed hash for Decidim::Attributes::Model coercion" do
          expect(subject.to_h).to eq(id: "abc12345", title: { "en" => "My group" }, position: 2)
        end
      end

      describe "attribute readers" do
        it "exposes id, title and position" do
          expect(subject.id).to eq("abc12345")
          expect(subject.title).to eq("en" => "My group")
          expect(subject.position).to eq(2)
        end
      end
    end
  end
end
