# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe ResultsHelper do
      include_context "with a ranked borda vote"

      describe "#computes_results?" do
        it "is true for a question whose voting method computes results" do
          expect(helper.computes_results?(question)).to be(true)
        end

        context "with a question whose voting method has no calculator" do
          let(:question) { create(:election_question, election:, question_type: "multiple_option") }

          it "is false" do
            expect(helper.computes_results?(question)).to be(false)
          end
        end
      end

      describe "#result_scores" do
        it "runs the calculator once per question and memoizes" do
          allow(Decidim::ExtraCensuses::BordaScorer).to receive(:new).and_call_original
          helper.result_scores(question)
          helper.result_scores(question)
          expect(Decidim::ExtraCensuses::BordaScorer).to have_received(:new).once
        end
      end

      describe "#score_for" do
        it "reads totals straight from the calculator" do
          expect(helper.score_for(question, option_a)).to eq(7)
          expect(helper.score_for(question, option_b)).to eq(7)
          expect(helper.score_for(question, option_c)).to eq(2)
        end

        it "returns 0 for an option nobody ranked" do
          expect(helper.score_for(question, option_d)).to eq(0)
        end
      end

      describe "#score_total" do
        it "sums the scores of every option" do
          # A=7, B=7, C=2, D=0
          expect(helper.score_total(question)).to eq(16)
        end

        context "when there are no votes" do
          before { question.votes.destroy_all }

          it "is 0" do
            expect(helper.score_total(question)).to eq(0)
          end
        end
      end

      describe "#score_percentage" do
        it "gives each option its share of the total score" do
          expect(helper.score_percentage(question, option_a)).to eq(43.8)
          expect(helper.score_percentage(question, option_c)).to eq(12.5)
        end

        it "is 0 for an option nobody ranked" do
          expect(helper.score_percentage(question, option_d)).to eq(0.0)
        end

        context "when there are no votes" do
          before { question.votes.destroy_all }

          it "is 0 instead of dividing by zero" do
            expect(helper.score_percentage(question, option_a)).to eq(0)
          end
        end
      end
    end
  end
end
