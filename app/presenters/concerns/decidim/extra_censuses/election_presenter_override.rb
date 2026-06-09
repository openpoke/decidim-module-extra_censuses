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
          end

          data
        end

        private

        def extra_censuses_annotate_results(question_hash, scorer)
          totals = scorer.totals_by_response_option

          Array(question_hash[:response_options]).each do |option_hash|
            # Only annotate options whose results the upstream gate already exposed
            # (the option hash carries :votes_count only when admin || published).
            next unless option_hash.has_key?(:votes_count)

            score = totals.fetch(option_hash[:id], 0)
            option_hash[:borda_score] = score
            option_hash[:borda_score_text] = I18n.t("decidim.extra_censuses.elections.results.borda.points", count: score)
          end
        end
      end
    end
  end
end
