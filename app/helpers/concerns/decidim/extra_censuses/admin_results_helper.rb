# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Admin results-table helpers for the BORDA Score column; totals come from
    # BordaScorer.
    module AdminResultsHelper
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
      end
    end
  end
end
