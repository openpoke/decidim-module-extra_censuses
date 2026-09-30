# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Confirmation-summary helper for the voter-facing ranked (BORDA) vote.
    module BordaVotingHelper
      extend ActiveSupport::Concern

      included do
        # BORDA buffers a { option_id => position } hash; standard questions keep
        # the upstream array shape handled by Question#safe_responses.
        def confirm_selected_options(question, buffered)
          return question.safe_responses(buffered) unless question.voting_method == "borda"
          return [] if buffered.blank?

          positions = Decidim::ExtraCensuses::VotingMethods::Borda::BufferedPositions.stringify(buffered).reject { |_id, pos| pos.to_s.strip.empty? }
          ordered_ids = positions.sort_by { |_id, pos| pos.to_i }.map { |id, _pos| id.to_i }
          by_id = question.response_options.where(id: ordered_ids).index_by(&:id)
          ordered_ids.filter_map { |id| by_id[id] }
        end
      end
    end
  end
end
