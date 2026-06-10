# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Results-table helpers shared by the admin dashboard and the public
    # elections views. Numbers come from the question's voting-method calculator.
    module ResultsHelper
      extend ActiveSupport::Concern

      # Single source for the score share shown in HTML and live-update JSON.
      def self.percentage(score, total)
        return 0 if total.to_i <= 0

        (score.to_f / total * 100).round(1)
      end

      included do
        def computes_results?(question)
          !!question.voting_method_manifest&.computes_results?
        end

        def result_scores(question)
          @result_scores ||= {}
          @result_scores[question.id] ||= results_calculator(question).totals_by_response_option
        end

        def score_for(question, option)
          result_scores(question).fetch(option.id, 0)
        end

        def score_total(question)
          @score_total ||= {}
          @score_total[question.id] ||= result_scores(question).values.sum
        end

        def score_percentage(question, option)
          Decidim::ExtraCensuses::ResultsHelper.percentage(score_for(question, option), score_total(question))
        end

        private

        def results_calculator(question)
          @results_calculators ||= {}
          @results_calculators[question.id] ||= question.voting_method_manifest.results_calculator_for(question)
        end
      end
    end
  end
end
