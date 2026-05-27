# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe BordaScorer do
      subject(:scorer) { described_class.new(question) }

      let(:election) { create(:election, :ongoing) }
      let(:question) { create(:election_question, :borda, election:, max_choices: 4, scoring_scale:) }
      let(:scoring_scale) { "start_from_max" }
      let!(:option_a) { create(:election_response_option, question:) }
      let!(:option_b) { create(:election_response_option, question:) }
      let!(:option_c) { create(:election_response_option, question:) }
      let!(:option_d) { create(:election_response_option, question:) }

      def cast(voter_uid, ranks)
        ranks.each do |option, position|
          create(:election_vote, question:, response_option: option, voter_uid:, position:)
        end
      end

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

      describe "#per_voter_breakdown" do
        let(:scoring_scale) { "start_from_max" }

        context "when the question is not borda" do
          let(:question) { create(:election_question, election:, question_type: "multiple_option") }

          it "returns an empty array" do
            expect(scorer.per_voter_breakdown).to eq([])
          end
        end

        context "with two voters" do
          before do
            cast("voter-1", { option_a => 1, option_b => 2 })
            cast("voter-2", { option_c => 1 })
          end

          it "returns one entry per voter with voter_uid and ranks hash" do
            breakdown = scorer.per_voter_breakdown
            expect(breakdown.size).to eq(2)
            voter1 = breakdown.find { |b| b.voter_uid == "voter-1" }
            voter2 = breakdown.find { |b| b.voter_uid == "voter-2" }
            expect(voter1.ranks).to eq(option_a.id => 1, option_b.id => 2)
            expect(voter2.ranks).to eq(option_c.id => 1)
          end
        end
      end
    end
  end
end
