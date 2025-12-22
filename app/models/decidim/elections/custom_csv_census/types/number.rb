# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Validates that value contains only digits.
        class Number < Base
          def self.validate(value)
            "invalid_number" unless value.match?(/\A\d+\z/)
          end
        end
      end
    end
  end
end
