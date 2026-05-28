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
            payload = data[question.id.to_s]
            if question.voting_method == "borda"
              positions = normalised_borda_positions(payload)
              next if positions.nil?

              responses = question.response_options.where(id: positions.keys).to_a
              next if responses.size != positions.size

              borda_positions[question.id] = positions
              [question, responses]
            else
              next if payload.is_a?(Hash)

              responses = question.safe_responses(payload)
              [question, responses]
            end
          end.to_h
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

        def normalised_borda_positions(payload)
          return nil unless payload.is_a?(Hash) || payload.is_a?(ActionController::Parameters)

          pairs = payload.respond_to?(:to_unsafe_h) ? payload.to_unsafe_h : payload
          pairs.each_with_object({}) do |(option_id, position), memo|
            next if position.to_s.strip.empty?

            int_position = Integer(position.to_s, 10)
            int_option_id = Integer(option_id.to_s, 10)
            memo[int_option_id] = int_position
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
