# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe ResponseOptionLabel do
      subject do
        described_class.new(
          "title" => { "en" => "Winner" },
          "description" => { "en" => "The top option" },
          "position" => "2",
          "color" => "green"
        )
      end

      describe "attribute readers" do
        it "exposes the multilang title and description" do
          expect(subject.title).to eq("en" => "Winner")
          expect(subject.description).to eq("en" => "The top option")
        end

        it "exposes color" do
          expect(subject.color).to eq("green")
        end
      end

      describe "#position" do
        it "is coerced to an integer when set" do
          expect(subject.position).to eq(2)
        end

        it "is nil when missing" do
          expect(described_class.new("title" => { "en" => "x" }).position).to be_nil
        end

        it "is nil when blank" do
          expect(described_class.new("title" => { "en" => "x" }, "position" => "").position).to be_nil
        end
      end

      describe "#present?" do
        it "is present when the title has a value" do
          expect(subject).to be_present
        end

        it "is not present when the title is missing" do
          expect(described_class.new({})).not_to be_present
        end

        it "is not present when the title hash is empty" do
          expect(described_class.new("title" => {})).not_to be_present
        end

        it "is not present when every locale value is empty" do
          expect(described_class.new("title" => { "en" => "" })).not_to be_present
        end
      end

      describe "#css_style" do
        it "returns the inline badge style for a known token" do
          expect(described_class.new("color" => "green").css_style).to eq("background-color: #E3FCE9; color: #15602C; border-color: #15602C;")
        end

        it "returns an empty string for a blank or unknown color" do
          expect(described_class.new("color" => "").css_style).to eq("")
          expect(described_class.new("color" => "turquoise").css_style).to eq("")
          expect(described_class.new({}).css_style).to eq("")
        end
      end
    end
  end
end
