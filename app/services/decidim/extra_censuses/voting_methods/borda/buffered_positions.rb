# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        # response_option_id (String) => position (String) for a voter's ranked
        # vote: the session buffer when present, otherwise the persisted vote.
        # Single source shared by the response-options cell and the confirm helper.
        class BufferedPositions
          def self.stringify(hash)
            pairs = hash.respond_to?(:to_unsafe_h) ? hash.to_unsafe_h : hash
            pairs.each_with_object({}) do |(option_id, position), memo|
              memo[option_id.to_s] = position.to_s
            end
          end

          def initialize(votes_buffer:, voter_uid:, question:)
            @votes_buffer = votes_buffer
            @voter_uid = voter_uid
            @question = question
          end

          def to_h
            buffered = @votes_buffer[@question.id.to_s]
            return self.class.stringify(buffered) if buffered.is_a?(Hash) || buffered.is_a?(ActionController::Parameters)

            @question.votes.where(voter_uid: @voter_uid).where.not(position: nil).each_with_object({}) do |vote, memo|
              memo[vote.response_option_id.to_s] = vote.position.to_s
            end
          end
        end
      end
    end
  end
end
