# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      class ParsedResponses
        attr_reader :responses, :positions

        def initialize(responses:, positions: {})
          @responses = responses
          @positions = positions
        end
      end
    end
  end
end
