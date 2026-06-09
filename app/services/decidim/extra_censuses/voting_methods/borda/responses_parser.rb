# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        class ResponsesParser
          def initialize(question)
            @question = question
          end

          def parse(payload)
            positions = parse_payload(payload)
            return if positions.nil?

            responses = @question.response_options.where(id: positions.keys).to_a
            return if responses.size != positions.size

            Decidim::ExtraCensuses::VotingMethods::ParsedResponses.new(responses:, positions:)
          end

          def validate!(parsed)
            positions = parsed.positions
            ranked_options_count = positions.size
            min = @question.min_choices.to_i
            max = @question.max_votable_options

            raise StandardError, "Borda vote has no positions for question #{@question.id}" if ranked_options_count.zero?
            raise StandardError, "Borda vote below min_choices for question #{@question.id}" if min.positive? && ranked_options_count < min
            raise StandardError, "Borda vote above max_choices for question #{@question.id}" if max.positive? && ranked_options_count > max

            values = positions.values.sort
            expected = (1..ranked_options_count).to_a
            return if values == expected

            raise StandardError, "Borda vote positions are not contiguous for question #{@question.id}"
          end

          private

          def parse_payload(payload)
            pairs = payload.try(:to_unsafe_h) || payload
            return unless pairs.is_a?(Hash)

            pairs.each_with_object({}) do |(option_id, rank), positions|
              next if rank.to_s.strip.empty?

              positions[Integer(option_id.to_s, 10)] = Integer(rank.to_s, 10)
            end
          rescue ArgumentError, TypeError
            nil
          end
        end
      end
    end
  end
end
