# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Validates that value is a valid date and normalizes to ISO format.
        class Date < Base
          def self.validate(value)
            parsed = ::Date._parse(value)
            return "invalid_date" unless parsed.any?
            return "invalid_date" unless parsed[:year] && parsed[:mon] && parsed[:mday]

            nil
          end

          def self.transform(value)
            parsed = ::Date._parse(value)
            return value unless parsed[:year] && parsed[:mon] && parsed[:mday]

            # Normalize to ISO format YYYY-MM-DD
            format("%04d-%02d-%02d", parsed[:year], parsed[:mon], parsed[:mday])
          end
        end
      end
    end
  end
end
