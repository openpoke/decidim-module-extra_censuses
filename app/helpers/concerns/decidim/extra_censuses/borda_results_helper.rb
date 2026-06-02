# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Public results helpers for BORDA questions; totals come from BordaScorer.
    module BordaResultsHelper
      extend ActiveSupport::Concern

      included do
        def borda_results?(question)
          question.voting_method == "borda"
        end

        # Memoized so the scorer runs once per question render.
        def borda_scores(question)
          @borda_scores ||= {}
          @borda_scores[question.id] ||= Decidim::ExtraCensuses::BordaScorer.new(question).totals_by_response_option
        end

        def borda_score_for(question, option)
          borda_scores(question).fetch(option.id, 0)
        end

        def borda_score_width(question, option)
          max = borda_scores(question).values.max.to_i
          return 0 if max <= 0

          (borda_score_for(question, option).to_f / max * 100).round(1)
        end

        def borda_ballots_count(question)
          Decidim::ExtraCensuses::BordaScorer.new(question).ballots_count
        end
      end
    end
  end
end
