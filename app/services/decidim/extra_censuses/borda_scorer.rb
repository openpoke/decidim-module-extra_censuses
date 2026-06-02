# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    class BordaScorer
      VoterBreakdown = Struct.new(:voter_uid, :ranks)

      def initialize(question)
        @question = question
      end

      def totals_by_response_option
        return {} unless question.voting_method == "borda"

        totals = Hash.new(0)
        votes_by_voter.each do |_voter_uid, rows|
          k = rows.size
          rows.each do |row|
            position = row.position.to_i
            next if position < 1

            totals[row.response_option_id] += question.borda_points(position, k)
          end
        end
        totals
      end

      def per_voter_breakdown
        return [] unless question.voting_method == "borda"

        votes_by_voter.map do |voter_uid, rows|
          ranks = rows.each_with_object({}) do |row, memo|
            memo[row.response_option_id] = row.position.to_i
          end
          VoterBreakdown.new(voter_uid, ranks)
        end
      end

      private

      attr_reader :question

      def votes_by_voter
        @votes_by_voter ||= question.votes.where.not(position: nil)
                                    .select(:voter_uid, :response_option_id, :position)
                                    .group_by(&:voter_uid)
      end
    end
  end
end
