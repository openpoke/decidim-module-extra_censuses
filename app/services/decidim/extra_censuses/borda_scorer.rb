# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    class BordaScorer
      def initialize(question)
        @question = question
      end

      def totals_by_response_option
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

      def ballots_count
        votes_by_voter.size
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
