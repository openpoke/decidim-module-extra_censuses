# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Strips leading and trailing spaces.
        class TextTrim < Base
          def self.transform(value)
            return nil if value.nil?

            value.to_s.strip
          end
        end
      end
    end
  end
end
