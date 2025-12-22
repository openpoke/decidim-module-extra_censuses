# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      # Represents a single column definition for custom CSV census.
      # Each column has a name and a type that determines validation/transformation rules.
      class ColumnDefinition
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :name, :string
        attribute :column_type, :string, default: "free_text"

        validates :name, presence: true
        validates :column_type, inclusion: { in: ->(record) { record.available_types } }

        def available_types
          Decidim::ExtraCensuses.column_types
        end

        def self.from_hash(hash)
          new(
            name: hash["name"] || hash[:name],
            column_type: hash["column_type"] || hash[:column_type] || "free_text"
          )
        end

        def to_hash
          {
            name: name,
            column_type: column_type
          }
        end

        # Transform value according to column type
        def transform(value)
          return nil if value.nil?

          case column_type
          when "alphanumeric"
            value.to_s.gsub(/[^A-Za-z0-9]/, "")
          when "text_trim", "date"
            value.to_s.strip
          when "number"
            value.to_s.gsub(/[^0-9\-.]/, "")
          else # free_text
            value.to_s
          end
        end

        # Validate value according to column type
        def validate_value(value)
          return { valid: true } if value.blank?

          case column_type
          when "alphanumeric"
            validate_alphanumeric(value)
          when "number"
            validate_number(value)
          when "date"
            validate_date(value)
          else
            { valid: true }
          end
        end

        private

        def validate_alphanumeric(value)
          return { valid: true } if value.to_s.match?(/\A[A-Za-z0-9]+\z/)

          { valid: false, error: "invalid_alphanumeric" }
        end

        def validate_number(value)
          return { valid: false, error: "invalid_number" } unless value.to_s.match?(/\A-?\d+(\.\d+)?\z/)

          { valid: true }
        end

        def validate_date(value)
          Date.parse(value.to_s)
          { valid: true }
        rescue ArgumentError
          { valid: false, error: "invalid_date" }
        end
      end
    end
  end
end
