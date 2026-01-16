# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Validates that value is a valid date.
        class Date < Base
          def self.validate(value)
            "invalid_date" unless ::Date._parse(value).any?
          end
        end
      end
    end
  end
end
