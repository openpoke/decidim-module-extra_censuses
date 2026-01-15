# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      module Types
        # Base class for column types.
        class Base
          def self.validate(value)
            return nil if value.nil?

            nil
          end

          def self.transform(value)
            return nil if value.nil?

            value.to_s
          end
        end
      end
    end
  end
end
