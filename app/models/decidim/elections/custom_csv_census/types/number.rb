# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Validates that value contains only digits.
        class Number < Base
          def self.validate(value)
            return nil if value.nil?

            "invalid_number" unless value.to_s.strip.match?(/\A\d+\z/)
          end

          def self.transform(value)
            return nil if value.nil?

            value.to_s.strip
          end
        end
      end
    end
  end
end
