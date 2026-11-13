# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module ElectionPresenterOverride
      extend ActiveSupport::Concern

      included do
        alias_method :extra_censuses_original_to_json, :to_json

        def to_json(admin: false)
          data = extra_censuses_original_to_json(admin:)

          questions_by_id = questions.index_by(&:id)

          Array(data[:questions]).each do |question_hash|
            question = questions_by_id[question_hash[:id]]
            manifest = question&.voting_method_manifest
            next unless manifest&.computes_results?

            extra_censuses_annotate_results(question_hash, manifest.results_calculator_for(question))
            extra_censuses_annotate_exclusive_option(question_hash, question)
          end

          data
        end

        private

        def extra_censuses_annotate_results(question_hash, scorer)
          totals = scorer.totals_by_response_option
          total = totals.values.sum

          if question_hash.has_key?(:total_votes)
            question_hash[:result_score_total_text] =
              I18n.t("decidim.extra_censuses.elections.results.points", count: total)
          end

          Array(question_hash[:response_options]).each do |option_hash|
            # Only annotate options whose results the upstream gate already exposed
            # (the option hash carries :votes_count only when admin || published).
            next unless option_hash.has_key?(:votes_count)

            score = totals.fetch(option_hash[:id], 0)
            option_hash[:result_score] = score
            option_hash[:result_score_text] = I18n.t("decidim.extra_censuses.elections.results.points", count: score)
            option_hash[:result_score_percent_text] = number_to_percentage(Decidim::ExtraCensuses::ResultsHelper.percentage(score, total), precision: 1)
          end
        end

        def extra_censuses_annotate_exclusive_option(question_hash, question)
          return unless question.exclusive_option?

          option = question.exclusive_response_option
          option_hash = Array(question_hash[:response_options]).find { |hash| hash[:id] == option&.id }
          return unless option_hash&.has_key?(:votes_count)

          option_hash[:voters_percent] = option.voters_percent
          option_hash[:voters_percent_text] = number_to_percentage(option.voters_percent, precision: 1)
        end
      end
    end
  end
end
