# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Results-table helpers shared by the admin dashboard and the public
    # elections views. Numbers come from the question's voting-method calculator.
    module ResultsHelper
      extend ActiveSupport::Concern

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

        def score_width(question, option)
          max = result_scores_max(question)
          return 0 if max <= 0

          (score_for(question, option).to_f / max * 100).round(1)
        end

        def score_total(question)
          @score_total ||= {}
          @score_total[question.id] ||= result_scores(question).values.sum
        end

        def score_percentage(question, option)
          total = score_total(question)
          return 0 if total <= 0

          (score_for(question, option).to_f / total * 100).round(1)
        end

        def voters_count(question)
          results_calculator(question).ballots_count
        end

        private

        def results_calculator(question)
          @results_calculators ||= {}
          @results_calculators[question.id] ||= question.voting_method_manifest.results_calculator_for(question)
        end

        def result_scores_max(question)
          @result_scores_max ||= {}
          @result_scores_max[question.id] ||= result_scores(question).values.max.to_i
        end
      end
    end
  end
end
