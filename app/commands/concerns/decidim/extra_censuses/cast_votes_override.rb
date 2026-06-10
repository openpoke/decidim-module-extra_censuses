# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module CastVotesOverride
      extend ActiveSupport::Concern

      included do
        private

        def voted_questions
          @voted_questions ||= election.available_questions.where(id: data.keys).filter_map do |question|
            parsed = responses_for(question, data[question.id.to_s])
            next if parsed.nil?

            [question, parsed]
          end.to_h
        end

        def responses_for(question, payload)
          parser = parser_for(question)
          return parser.parse(payload) if parser
          return if payload.is_a?(Hash)

          Decidim::ExtraCensuses::VotingMethods::ParsedResponses.new(responses: question.safe_responses(payload))
        end

        def save_votes!
          voted_questions.each do |question, parsed|
            raise StandardError, "No responses for question #{question.id}" if parsed.responses.blank?

            parser_for(question)&.validate!(parsed)
            question.votes.where(voter_uid:).destroy_all
            parsed.responses.each do |response_option|
              question.votes.create!(
                voter_uid:,
                response_option:,
                position: parsed.positions[response_option.id]
              )
            end
          end
        end

        def parser_for(question)
          klass = question.voting_method_manifest&.responses_parser
          klass&.constantize&.new(question)
        end
      end
    end
  end
end
