# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # View helpers for the voter-facing ranked (BORDA) ballot. Mounted on the
    # public voting controllers from the engine.
    module BordaVotingHelper
      extend ActiveSupport::Concern

      included do
        # Stimulus identifier mounted on the response-options container, blank for
        # non-BORDA questions so the controller stays inert.
        def borda_controller_name(question)
          "voter-borda" if question.voting_method == "borda"
        end

        def borda?(question)
          question.voting_method == "borda"
        end

        # Raw (uninterpolated) i18n templates fed to the Stimulus controller, which
        # substitutes %{ordinal} / %{count} client-side as the ballot size changes.
        def borda_label_one_template
          t("decidim.extra_censuses.elections.votes.borda.position_label", ordinal: "%{ordinal}", count: 1)
        end

        def borda_label_other_template
          t("decidim.extra_censuses.elections.votes.borda.position_label", ordinal: "%{ordinal}", count: "%{count}")
        end

        def borda_counter_template
          t("decidim.extra_censuses.elections.votes.borda.selected_counter", count: "%{count}", max: "%{max}")
        end

        # response_option_id (String) => position (String), from the session
        # buffer when present, otherwise from the voter's persisted ballot.
        def borda_buffered_positions(question)
          Decidim::ExtraCensuses::VotingMethods::Borda::BufferedPositions.new(
            votes_buffer:, voter_uid:, question:
          ).to_h
        end

        # Selected options for the confirmation summary. BORDA buffers a
        # { option_id => position } hash ordered by rank; standard questions keep
        # the upstream array shape handled by Question#safe_responses.
        def confirm_selected_options(question, buffered)
          return question.safe_responses(buffered) unless question.voting_method == "borda"
          return [] if buffered.blank?

          positions = stringify_positions(buffered).reject { |_id, pos| pos.to_s.strip.empty? }
          ordered_ids = positions.sort_by { |_id, pos| pos.to_i }.map { |id, _pos| id.to_i }
          by_id = question.response_options.where(id: ordered_ids).index_by(&:id)
          ordered_ids.filter_map { |id| by_id[id] }
        end

        # JSON array of ordinal strings indexed by position - 1, consumed by the
        # Stimulus controller to relabel selects under start_from_min.
        def borda_ordinals_json(question)
          (1..question.max_votable_options).map { |pos| ActiveSupport::Inflector.ordinalize(pos) }.to_json
        end

        # `ballot_size` is the full ballot length k, so start_from_min points
        # match even when `options` is just one group.
        def borda_confirm_rows(question, options, ballot_size)
          positions = borda_buffered_positions(question)
          options
            .map { |option| [option, positions[option.id.to_s].to_i] }
            .sort_by { |_option, rank| rank }
            .map { |option, rank| [option, rank, question.borda_points(rank, ballot_size)] }
        end

        private

        def stringify_positions(hash)
          Decidim::ExtraCensuses::VotingMethods::Borda::BufferedPositions.stringify(hash)
        end
      end
    end
  end
end
