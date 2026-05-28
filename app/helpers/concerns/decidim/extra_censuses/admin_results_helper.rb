# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # View helpers for the admin results table. Adds the BORDA "Score" column,
    # reading totals straight from BordaScorer (never recomputing them here).
    module AdminResultsHelper
      extend ActiveSupport::Concern

      included do
        def borda_results?(question)
          question.voting_method == "borda"
        end

        # response_option_id => total Borda points, memoized so the scorer runs
        # once per question render.
        def borda_scores(question)
          @borda_scores ||= {}
          @borda_scores[question.id] ||= Decidim::ExtraCensuses::BordaScorer.new(question).totals_by_response_option
        end

        def borda_score_for(question, option)
          borda_scores(question).fetch(option.id, 0)
        end

        # Options sorted by score descending, then by id ascending (tiebreak).
        def borda_ordered_response_options(question, options)
          scores = borda_scores(question)
          options.sort_by { |option| [-scores.fetch(option.id, 0), option.id] }
        end
      end
    end
  end
end
