# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe QuestionOverride do
      let(:election) { create(:election) }

      describe "#voting_method_manifest" do
        context "when the question uses borda" do
          let(:question) { create(:election_question, :borda, election:, max_choices: 3) }

          it "returns the borda manifest" do
            expect(question.voting_method_manifest.name).to eq(:borda)
          end
        end

        context "when the question uses the default (approval)" do
          let(:question) { create(:election_question, election:, settings: {}) }

          it "has no manifest, falling back to upstream behaviour" do
            expect(question.voting_method_manifest).to be_nil
          end
        end

        context "when the question has an unregistered voting_method" do
          let(:question) { create(:election_question, election:, settings: {}) }

          before { allow(question).to receive(:voting_method).and_return("ranked_pairs") }

          it "has no manifest" do
            expect(question.voting_method_manifest).to be_nil
          end
        end
      end
    end
  end
end
