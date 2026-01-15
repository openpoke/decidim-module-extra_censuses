# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Validates that value is a valid date and normalizes to ISO format.
        class Date < Base
          def self.validate(value)
            return nil if value.nil?

            parsed = ::Date._parse(value.to_s)
            return "invalid_date" unless parsed.any?
            return "invalid_date" unless parsed[:year] && parsed[:mon] && parsed[:mday]

            nil
          end

          def self.transform(value)
            return nil if value.nil?

            str = value.to_s
            parsed = ::Date._parse(str)
            return str unless parsed[:year] && parsed[:mon] && parsed[:mday]

            format("%04d-%02d-%02d", parsed[:year], parsed[:mon], parsed[:mday])
          end
        end
      end
    end
  end
end
