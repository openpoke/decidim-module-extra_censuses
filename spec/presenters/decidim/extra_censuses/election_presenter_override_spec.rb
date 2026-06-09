# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe ElectionPresenterOverride do
      include_context "with a borda question"

      subject(:presenter) { election.presenter }

      def option_hash_for(json, question, option)
        question_hash = json[:questions].find { |q| q[:id] == question.id }
        question_hash[:response_options].find { |o| o[:id] == option.id }
      end

      describe "#to_json with admin: true" do
        include_context "with a ranked borda ballot"

        let(:json) { presenter.to_json(admin: true) }
        let(:totals) { Decidim::ExtraCensuses::BordaScorer.new(question).totals_by_response_option }

        it "annotates each borda option with borda_score and borda_score_text" do
          expect(option_hash_for(json, question, option_a)).to include(
            borda_score: totals.fetch(option_a.id),
            borda_score_text: I18n.t("decidim.extra_censuses.elections.results.borda.points", count: totals.fetch(option_a.id))
          )
          expect(option_hash_for(json, question, option_b)).to include(
            borda_score: totals.fetch(option_b.id),
            borda_score_text: I18n.t("decidim.extra_censuses.elections.results.borda.points", count: totals.fetch(option_b.id))
          )
          expect(option_hash_for(json, question, option_c)).to include(
            borda_score: totals.fetch(option_c.id),
            borda_score_text: I18n.t("decidim.extra_censuses.elections.results.borda.points", count: totals.fetch(option_c.id))
          )
        end

        it "matches BordaScorer totals exactly" do
          # A: (4-1+1) + (4-2+1) = 7, B: (4-2+1) + (4-1+1) = 7, C: (4-3+1) = 2
          expect(option_hash_for(json, question, option_a)[:borda_score]).to eq(7)
          expect(option_hash_for(json, question, option_b)[:borda_score]).to eq(7)
          expect(option_hash_for(json, question, option_c)[:borda_score]).to eq(2)
        end

        it "annotates each borda option with its score percentage text" do
          # total score = 7 + 7 + 2 = 16 -> A,B = 43.8%, C = 12.5%
          expect(option_hash_for(json, question, option_a)[:borda_score_percent_text]).to eq("43.8%")
          expect(option_hash_for(json, question, option_b)[:borda_score_percent_text]).to eq("43.8%")
          expect(option_hash_for(json, question, option_c)[:borda_score_percent_text]).to eq("12.5%")
        end

        it "reports score 0 for an unvoted borda option" do
          expect(option_hash_for(json, question, option_d)).to include(
            borda_score: 0,
            borda_score_text: I18n.t("decidim.extra_censuses.elections.results.borda.points", count: 0)
          )
        end
      end

      describe "#to_json with multiple questions (borda + non-borda)" do
        let(:standard_question) { create(:election_question, election:, question_type: "multiple_option") }
        let!(:standard_option) { create(:election_response_option, question: standard_question) }
        let(:json) { presenter.to_json(admin: true) }

        before { cast("voter-1", { option_a => 1, option_b => 2 }) }

        it "attaches scores to the borda question only and leaves the non-borda one untouched" do
          # start_from_max, max_choices = 4, A ranked 1 => 4, B ranked 2 => 3
          expect(option_hash_for(json, question, option_a)).to include(borda_score: 4, borda_score_text: I18n.t("decidim.extra_censuses.elections.results.borda.points", count: 4))
          expect(option_hash_for(json, question, option_b)).to include(borda_score: 3, borda_score_text: I18n.t("decidim.extra_censuses.elections.results.borda.points", count: 3))

          standard_option_hash = option_hash_for(json, standard_question, standard_option)
          expect(standard_option_hash).not_to have_key(:borda_score)
          expect(standard_option_hash).not_to have_key(:borda_score_text)
          expect(standard_option_hash).not_to have_key(:borda_score_percent_text)
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
          expect(option_hash).not_to have_key(:borda_score_percent_text)
        end
      end

      describe "#to_json public gate (admin: false, results unpublished)" do
        let(:json) { presenter.to_json }

        before { cast("voter-1", { option_a => 1, option_b => 2 }) }

        it "does not leak score keys when the option results are not exposed" do
          option_hash = option_hash_for(json, question, option_a)
          expect(option_hash).not_to have_key(:votes_count)
          expect(option_hash).not_to have_key(:borda_score)
          expect(option_hash).not_to have_key(:borda_score_text)
          expect(option_hash).not_to have_key(:borda_score_percent_text)
        end
      end

      describe "#to_json public gate (admin: false, results published)" do
        let(:election) { create(:election, :published_results, :real_time) }
        let(:json) { presenter.to_json }

        before { cast("voter-1", { option_a => 1, option_b => 2 }) }

        it "carries score keys once results are published" do
          option_hash = option_hash_for(json, question, option_a)
          # start_from_max, max_choices = 4, A ranked 1 => 4 - 1 + 1 = 4
          expect(option_hash).to have_key(:votes_count)
          expect(option_hash).to include(
            borda_score: 4,
            borda_score_text: I18n.t("decidim.extra_censuses.elections.results.borda.points", count: 4)
          )
        end
      end
    end
  end
end
