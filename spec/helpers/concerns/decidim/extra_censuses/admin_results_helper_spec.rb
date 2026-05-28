# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe AdminResultsHelper do
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

      before do
        # max_choices = 4, start_from_max => pts = 4 - position + 1
        # voter 1: A=1 (4 pts), B=2 (3 pts), C=3 (2 pts)
        # voter 2: B=1 (4 pts), A=2 (3 pts)
        # totals: A=7, B=7, C=2, D=0 (unvoted)
        cast("voter-1", { option_a => 1, option_b => 2, option_c => 3 })
        cast("voter-2", { option_b => 1, option_a => 2 })
      end

      describe "#borda_results?" do
        it "is true for a borda question" do
          expect(helper.borda_results?(question)).to be(true)
        end

        context "with a non-borda question" do
          let(:question) { create(:election_question, election:, question_type: "multiple_option") }

          it "is false" do
            expect(helper.borda_results?(question)).to be(false)
          end
        end
      end

      describe "#borda_score_for" do
        it "reads totals straight from BordaScorer" do
          expect(helper.borda_score_for(question, option_a)).to eq(7)
          expect(helper.borda_score_for(question, option_b)).to eq(7)
          expect(helper.borda_score_for(question, option_c)).to eq(2)
        end

        it "returns 0 for an option nobody ranked" do
          expect(helper.borda_score_for(question, option_d)).to eq(0)
        end
      end

      describe "#borda_ordered_response_options" do
        it "sorts by score descending, then by id ascending on ties" do
          # Feed the options in a shuffled order to prove the helper, not input order, decides.
          ordered = helper.borda_ordered_response_options(question, [option_d, option_c, option_b, option_a])
          # A=7, B=7 (tie -> lower id first), C=2, D=0.
          tie_winners = [option_a, option_b].sort_by(&:id)
          expect(ordered).to eq([tie_winners.first, tie_winners.last, option_c, option_d])
        end
      end

      describe "#borda_scores" do
        it "calls BordaScorer once per question and memoizes" do
          allow(Decidim::ExtraCensuses::BordaScorer).to receive(:new).and_call_original
          helper.borda_scores(question)
          helper.borda_scores(question)
          expect(Decidim::ExtraCensuses::BordaScorer).to have_received(:new).once
        end
      end
    end
  end
end
