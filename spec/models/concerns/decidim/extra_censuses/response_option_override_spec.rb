# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe ResponseOptionOverride do
      let(:response_option) { build(:election_response_option) }

      describe "#label" do
        context "when settings has no label" do
          it "returns nil" do
            expect(response_option.label).to be_nil
          end
        end

        context "when settings stores a label hash" do
          let(:response_option) { build(:election_response_option, :with_label) }

          it "returns a ResponseOptionLabel value object" do
            expect(response_option.label).to be_a(Decidim::ExtraCensuses::ResponseOptionLabel)
            expect(response_option.label.title).to eq("en" => "Winner")
            expect(response_option.label.position).to eq(1)
            expect(response_option.label.color).to eq("green")
          end
        end

        context "when the stored title is empty" do
          let(:response_option) { build(:election_response_option, settings: { "label" => { "title" => {} } }) }

          it "returns a blank value object" do
            expect(response_option.label).to be_blank
          end
        end
      end

      describe "#labeled?" do
        it "is false when there is no label" do
          expect(response_option.labeled?).to be false
        end

        context "when a label is set" do
          let(:response_option) { build(:election_response_option, :with_label) }

          it "is true" do
            expect(response_option.labeled?).to be true
          end
        end

        context "when the stored title is empty" do
          let(:response_option) { build(:election_response_option, settings: { "label" => { "title" => { "en" => "" } } }) }

          it "is false" do
            expect(response_option.labeled?).to be false
          end
        end
      end
    end
  end
end
