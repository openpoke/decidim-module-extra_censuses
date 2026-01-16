# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Strips all characters except A-Z, a-z, 0-9.
        class Alphanumeric < Base
          def self.transform(value)
            value.gsub(/[^A-Za-z0-9]/, "")
          end
        end
      end
    end
  end
end
