# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module CastVotesOverride
      extend ActiveSupport::Concern

      included do
        alias_method :extra_censuses_original_voted_questions, :voted_questions
        alias_method :extra_censuses_original_save_votes!, :save_votes!

        private

        def voted_questions
          @voted_questions ||= election.available_questions.where(id: data.keys).filter_map do |question|
            responses = responses_for(question, data[question.id.to_s])
            next if responses.nil?

            [question, responses]
          end.to_h
        end

        def responses_for(question, payload)
          return borda_responses(question, payload) if question.voting_method == "borda"
          return if payload.is_a?(Hash)

          question.safe_responses(payload)
        end

        def borda_responses(question, payload)
          positions = parse_borda_payload(payload)
          return if positions.nil?

          responses = question.response_options.where(id: positions.keys).to_a
          return if responses.size != positions.size

          borda_positions[question.id] = positions
          responses
        end

        def save_votes!
          voted_questions.each do |question, responses|
            raise StandardError, "No responses for question #{question.id}" if responses.blank?

            if question.voting_method == "borda"
              save_borda_votes!(question, responses)
            else
              question.votes.where(voter_uid: voter_uid).destroy_all
              responses.each do |response_option|
                question.votes.create!(
                  voter_uid: voter_uid,
                  response_option: response_option
                )
              end
            end
          end
        end

        def save_borda_votes!(question, responses)
          positions = borda_positions[question.id] || {}
          validate_borda_positions!(question, positions)

          question.votes.where(voter_uid: voter_uid).destroy_all
          responses.each do |response_option|
            question.votes.create!(
              voter_uid: voter_uid,
              response_option: response_option,
              position: positions[response_option.id]
            )
          end
        end

        def borda_positions
          @borda_positions ||= {}
        end

        # { option_id => rank }, a Hash (session buffer) or ActionController::Parameters (per-question); nil if invalid.
        def parse_borda_payload(payload)
          pairs = payload.try(:to_unsafe_h) || payload
          return unless pairs.is_a?(Hash)

          pairs.each_with_object({}) do |(option_id, rank), positions|
            next if rank.to_s.strip.empty?

            positions[Integer(option_id.to_s, 10)] = Integer(rank.to_s, 10)
          end
        rescue ArgumentError, TypeError
          nil
        end

        def validate_borda_positions!(question, positions)
          k = positions.size
          min = question.min_choices.to_i
          max = (question.max_choices || question.response_options.size).to_i

          raise StandardError, "Borda ballot has no positions for question #{question.id}" if k.zero?
          raise StandardError, "Borda ballot below min_choices for question #{question.id}" if min.positive? && k < min
          raise StandardError, "Borda ballot above max_choices for question #{question.id}" if max.positive? && k > max

          values = positions.values.sort
          expected = (1..k).to_a
          return if values == expected

          raise StandardError, "Borda ballot positions are not contiguous for question #{question.id}"
        end
      end
    end
  end
end
