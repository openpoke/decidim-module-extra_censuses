# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe BordaScorer do
      include_context "with a borda question"

      subject(:scorer) { described_class.new(question) }

      describe "#totals_by_response_option" do
        context "when the question is not borda" do
          let(:question) { create(:election_question, election:, question_type: "multiple_option") }

          it "returns an empty hash" do
            expect(scorer.totals_by_response_option).to eq({})
          end
        end

        context "when there are no votes" do
          it "returns an empty hash" do
            expect(scorer.totals_by_response_option).to eq({})
          end
        end

        context "with start_from_max scoring (fixed scale)" do
          let(:scoring_scale) { "start_from_max" }

          before do
            # voter 1: A=1, B=2, C=3 (full ballot of 3 of 4)
            cast("voter-1", { option_a => 1, option_b => 2, option_c => 3 })
            # voter 2: B=1, A=2 (partial ballot of 2 of 4)
            cast("voter-2", { option_b => 1, option_a => 2 })
          end

          it "scores each option using max_choices - position + 1" do
            totals = scorer.totals_by_response_option
            # max_choices = 4
            # A: (4-1+1) + (4-2+1) = 4 + 3 = 7
            # B: (4-2+1) + (4-1+1) = 3 + 4 = 7
            # C: (4-3+1) = 2
            expect(totals[option_a.id]).to eq(7)
            expect(totals[option_b.id]).to eq(7)
            expect(totals[option_c.id]).to eq(2)
            expect(totals[option_d.id]).to be_nil.or eq(0)
          end
        end

        context "with start_from_max and a partial ballot shorter than max_choices" do
          let(:question) { create(:election_question, :borda, election:, max_choices: 5, scoring_scale: "start_from_max") }

          before do
            # base = max_votable_options = max_choices = 5 (not the ballot size of 2)
            cast("voter-1", { option_a => 1, option_b => 2 })
          end

          it "scores from max_choices, not the number of selected options" do
            totals = scorer.totals_by_response_option
            # rank 1 => 5 - 1 + 1 = 5, rank 2 => 5 - 2 + 1 = 4
            expect(totals[option_a.id]).to eq(5)
            expect(totals[option_b.id]).to eq(4)
          end
        end

        context "with start_from_min scoring (per-voter k scale)" do
          let(:scoring_scale) { "start_from_min" }

          before do
            cast("voter-1", { option_a => 1, option_b => 2, option_c => 3 })
            cast("voter-2", { option_b => 1, option_a => 2 })
          end

          it "scores each option using k - position + 1 per voter" do
            totals = scorer.totals_by_response_option
            # voter 1 k=3: A=3, B=2, C=1
            # voter 2 k=2: B=2, A=1
            # A: 3 + 1 = 4
            # B: 2 + 2 = 4
            # C: 1
            expect(totals[option_a.id]).to eq(4)
            expect(totals[option_b.id]).to eq(4)
            expect(totals[option_c.id]).to eq(1)
          end
        end

        context "when totals tie" do
          let(:scoring_scale) { "start_from_max" }

          before do
            cast("voter-1", { option_a => 1, option_b => 2 })
            cast("voter-2", { option_b => 1, option_a => 2 })
          end

          it "returns equal totals (tiebreak is the caller's concern)" do
            totals = scorer.totals_by_response_option
            expect(totals[option_a.id]).to eq(totals[option_b.id])
          end
        end
      end
    end
  end
end
