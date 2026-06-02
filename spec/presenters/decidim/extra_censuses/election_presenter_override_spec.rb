# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe ElectionPresenterOverride do
      subject(:presenter) { election.presenter }

      let(:election) { create(:election, :ongoing) }
      let(:borda_question) { create(:election_question, :borda, election:, max_choices: 4) }
      let!(:option_a) { create(:election_response_option, question: borda_question) }
      let!(:option_b) { create(:election_response_option, question: borda_question) }
      let!(:option_c) { create(:election_response_option, question: borda_question) }
      let!(:option_d) { create(:election_response_option, question: borda_question) }

      def cast(voter_uid, ranks)
        ranks.each do |option, position|
          create(:election_vote, question: borda_question, response_option: option, voter_uid:, position:)
        end
      end

      def option_hash_for(json, question, option)
        question_hash = json[:questions].find { |q| q[:id] == question.id }
        question_hash[:response_options].find { |o| o[:id] == option.id }
      end

      describe "#to_json with admin: true" do
        before do
          # voter 1: A=1, B=2, C=3 (start_from_max, max_choices = 4)
          cast("voter-1", { option_a => 1, option_b => 2, option_c => 3 })
          # voter 2: B=1, A=2
          cast("voter-2", { option_b => 1, option_a => 2 })
        end

        let(:json) { presenter.to_json(admin: true) }
        let(:totals) { Decidim::ExtraCensuses::BordaScorer.new(borda_question).totals_by_response_option }

        it "annotates each borda option with borda_score and borda_score_text" do
          expect(option_hash_for(json, borda_question, option_a)).to include(
            borda_score: totals.fetch(option_a.id),
            borda_score_text: totals.fetch(option_a.id).to_s
          )
          expect(option_hash_for(json, borda_question, option_b)).to include(
            borda_score: totals.fetch(option_b.id),
            borda_score_text: totals.fetch(option_b.id).to_s
          )
          expect(option_hash_for(json, borda_question, option_c)).to include(
            borda_score: totals.fetch(option_c.id),
            borda_score_text: totals.fetch(option_c.id).to_s
          )
        end

        it "matches BordaScorer totals exactly" do
          # A: (4-1+1) + (4-2+1) = 7, B: (4-2+1) + (4-1+1) = 7, C: (4-3+1) = 2
          expect(option_hash_for(json, borda_question, option_a)[:borda_score]).to eq(7)
          expect(option_hash_for(json, borda_question, option_b)[:borda_score]).to eq(7)
          expect(option_hash_for(json, borda_question, option_c)[:borda_score]).to eq(2)
        end

        it "reports score 0 for an unvoted borda option" do
          expect(option_hash_for(json, borda_question, option_d)).to include(
            borda_score: 0,
            borda_score_text: "0"
          )
        end
      end

      describe "#to_json with multiple questions (borda + non-borda)" do
        let(:standard_question) { create(:election_question, election:, question_type: "multiple_option") }
        let!(:standard_option) { create(:election_response_option, question: standard_question) }
        let(:json) { presenter.to_json(admin: true) }

        before do
          cast("voter-1", { option_a => 1, option_b => 2 })
        end

        it "attaches scores to the borda question only and leaves the non-borda one untouched" do
          # start_from_max, max_choices = 4, A ranked 1 => 4, B ranked 2 => 3
          expect(option_hash_for(json, borda_question, option_a)).to include(borda_score: 4, borda_score_text: "4")
          expect(option_hash_for(json, borda_question, option_b)).to include(borda_score: 3, borda_score_text: "3")

          standard_option_hash = option_hash_for(json, standard_question, standard_option)
          expect(standard_option_hash).not_to have_key(:borda_score)
          expect(standard_option_hash).not_to have_key(:borda_score_text)
        end
      end

      describe "#to_json with a non-borda question" do
        let(:standard_question) { create(:election_question, election:, question_type: "multiple_option") }
        let!(:standard_option) { create(:election_response_option, question: standard_question) }
        let(:json) { presenter.to_json(admin: true) }

        it "does not add borda score keys to its option hashes" do
          option_hash = option_hash_for(json, standard_question, standard_option)
          expect(option_hash).not_to have_key(:borda_score)
          expect(option_hash).not_to have_key(:borda_score_text)
        end
      end

      describe "#to_json public gate (admin: false, results unpublished)" do
        before do
          cast("voter-1", { option_a => 1, option_b => 2 })
        end

        let(:json) { presenter.to_json }

        it "does not leak score keys when the option results are not exposed" do
          option_hash = option_hash_for(json, borda_question, option_a)
          expect(option_hash).not_to have_key(:votes_count)
          expect(option_hash).not_to have_key(:borda_score)
          expect(option_hash).not_to have_key(:borda_score_text)
        end
      end

      describe "#to_json public gate (admin: false, results published)" do
        let(:election) { create(:election, :published_results, :real_time) }
        let(:json) { presenter.to_json }

        before do
          cast("voter-1", { option_a => 1, option_b => 2 })
        end

        it "carries score keys once results are published" do
          option_hash = option_hash_for(json, borda_question, option_a)
          # start_from_max, max_choices = 4, A ranked 1 => 4 - 1 + 1 = 4
          expect(option_hash).to have_key(:votes_count)
          expect(option_hash).to include(borda_score: 4, borda_score_text: "4")
        end
      end
    end
  end
end
