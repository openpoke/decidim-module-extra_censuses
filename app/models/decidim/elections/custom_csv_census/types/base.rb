# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Base class for column types.
        class Base
          def self.validate(_value)
            nil
          end

          def self.transform(value)
            value
          end
        end
      end
    end
  end
end
