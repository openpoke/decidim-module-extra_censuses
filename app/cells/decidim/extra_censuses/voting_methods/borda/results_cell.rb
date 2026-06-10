# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        # Mirrors the upstream `_vote_results_option` markup so the live poller
        # keeps updating the same data-* hooks.
        class ResultsCell < Decidim::ViewModel
          include Cell::ViewModel::Partial
          include Decidim::ExtraCensuses::ResultsHelper
          include Decidim::ExtraCensuses::GroupedResponseOptionsHelper

          def show
            render
          end

          private

          def election
            model.election
          end

          def label_shown?
            election.per_question? ? model.published_results? : election.finished?
          end

          def response_groups
            return [[nil, model.response_options.to_a]] unless model.grouped?

            grouped_response_options(model)
          end

          def ordered_options(options)
            return options unless label_shown?

            options.each_with_index.sort_by do |option, index|
              [option.labeled? ? 0 : 1, *label_sort_key(option, index)]
            end.map(&:first)
          end

          def show_winners_toggle?
            label_shown? && model.response_options.any?(&:labeled?)
          end

          def winner_options
            model.response_options.each_with_index
                 .select { |option, _index| option.labeled? }
                 .sort_by { |option, index| label_sort_key(option, index) }
                 .map(&:first)
          end

          # Position-set labels first (by value), then default order; the index
          # tiebreaker keeps the sort deterministic.
          def label_sort_key(option, index)
            [position_present?(option) ? 0 : 1, option.label&.position.to_i, index]
          end

          def position_present?(option)
            option.label&.position.present?
          end

          def winner_summary(option)
            t("decidim.extra_censuses.elections.results.borda.winner_summary",
              votes: t("votes_count", scope: "decidim.elections.elections.show", count: option.votes_count),
              points: t("decidim.extra_censuses.elections.results.points", count: score_for(model, option)),
              percent: number_to_percentage(score_percentage(model, option), precision: 1))
          end
        end
      end
    end
  end
end
