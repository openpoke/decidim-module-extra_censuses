# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      # Registry for column types.
      module Types
        REGISTRY = {
          "alphanumeric" => "Decidim::Elections::CustomCsvCensus::Types::Alphanumeric",
          "text_trim" => "Decidim::Elections::CustomCsvCensus::Types::TextTrim",
          "date" => "Decidim::Elections::CustomCsvCensus::Types::Date",
          "number" => "Decidim::Elections::CustomCsvCensus::Types::Number"
        }.freeze

        @cache = {}

        def self.find(name)
          @cache[name] ||= REGISTRY[name]&.constantize || Base
        end

        def self.validate(type_name, value) = find(type_name).validate(value)

        def self.transform(type_name, value) = find(type_name).transform(value)
      end
    end
  end
end
