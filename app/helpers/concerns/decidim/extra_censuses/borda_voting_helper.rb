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

        # [[label, position], ...] pairs for a position <select>.
        # Labels reflect the question's scoring scale at the maximum ballot size;
        # under start_from_min the Stimulus controller recomputes them per k.
        def borda_position_options(question)
          max = question.max_votable_options
          (1..max).map { |pos| [borda_position_label(question, pos, max), pos] }
        end

        # The position previously assigned to this option, or nil when unranked.
        def borda_response_position(question, option)
          borda_buffered_positions(question)[option.id.to_s].presence&.to_i
        end

        # response_option_id (String) => position (String), from the session
        # buffer when present, otherwise from the voter's persisted ballot.
        def borda_buffered_positions(question)
          buffered = votes_buffer[question.id.to_s]
          return stringify_positions(buffered) if buffered.is_a?(Hash) || buffered.is_a?(ActionController::Parameters)

          question.votes.where(voter_uid:).where.not(position: nil).each_with_object({}) do |vote, memo|
            memo[vote.response_option_id.to_s] = vote.position.to_s
          end
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

        def borda_position_label(question, position, ballot_size)
          t("decidim.extra_censuses.elections.votes.borda.position_label",
            ordinal: ActiveSupport::Inflector.ordinalize(position),
            count: question.borda_points(position, ballot_size))
        end

        # [[option, rank, points], ...] for the confirm summary, sorted by rank.
        # `options` is a subset (a single group, or the whole ballot when flat);
        # `ballot_size` is the full ballot length k so start_from_min points match.
        def borda_confirm_rows(question, options, ballot_size)
          positions = borda_buffered_positions(question)
          options
            .map { |option| [option, positions[option.id.to_s].to_i] }
            .sort_by { |_option, rank| rank }
            .map { |option, rank| [option, rank, question.borda_points(rank, ballot_size)] }
        end

        private

        def stringify_positions(hash)
          pairs = hash.respond_to?(:to_unsafe_h) ? hash.to_unsafe_h : hash
          pairs.each_with_object({}) do |(option_id, position), memo|
            memo[option_id.to_s] = position.to_s
          end
        end
      end
    end
  end
end
