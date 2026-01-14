# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Validates that value contains only digits.
        class Number < Base
          def self.validate(value)
            "invalid_number" unless value.strip.match?(/\A\d+\z/)
          end

          def self.transform(value)
            value.strip
          end
        end
      end
    end
  end
end
