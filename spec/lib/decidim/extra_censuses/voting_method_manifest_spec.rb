# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe VotingMethodManifest do
      subject { described_class.new(attributes) }

      let(:attributes) { { name: :borda } }

      describe "validations" do
        it "is valid with only a name (every other slot falls back to upstream)" do
          expect(subject).to be_valid
        end

        context "without a name" do
          let(:attributes) { { name: nil } }

          it "is invalid" do
            expect(subject).not_to be_valid
            expect(subject.errors[:name]).to be_present
          end
        end
      end

      describe "#computes_results?" do
        context "when a results_calculator is present" do
          let(:attributes) { { name: :borda, results_calculator: "Some::Calculator" } }

          it "is true" do
            expect(subject.computes_results?).to be true
          end
        end

        context "when the results_calculator is blank" do
          it "is false" do
            expect(subject.computes_results?).to be false
          end
        end
      end

      describe "#label" do
        it "falls back to the humanized name" do
          expect(subject.label).to eq("Borda")
        end
      end

      describe "#results_calculator_for" do
        context "when the results_calculator is blank" do
          it "returns nil" do
            expect(subject.results_calculator_for(double)).to be_nil
          end
        end
      end
    end
  end
end
