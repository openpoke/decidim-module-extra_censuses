# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      # Manages the collection of column definitions for a custom CSV census.
      # Stores configuration as JSON that can be saved with the election.
      class ColumnConfig
        include ActiveModel::Model

        attr_reader :columns

        def initialize(columns_data = [])
          @columns = parse_columns(columns_data)
        end

        def self.from_json(json_string)
          return new([]) if json_string.blank?

          data = JSON.parse(json_string)
          new(data["columns"] || [])
        rescue JSON::ParserError
          new([])
        end

        def to_json(*_args)
          {
            columns: columns.map(&:to_hash)
          }.to_json
        end

        def add_column(name:, column_type: "free_text")
          @columns << ColumnDefinition.new(
            name: name,
            column_type: column_type
          )
        end

        def remove_column(name)
          @columns.reject! { |col| col.name == name }
        end

        def column_names
          columns.map(&:name)
        end

        def find_column(name)
          columns.find { |col| col.name == name }
        end

        def valid?
          columns.all?(&:valid?) && columns.any?
        end

        def errors
          @errors ||= columns.each_with_object([]) do |col, errs|
            errs << "Column '#{col.name}': #{col.errors.full_messages.join(", ")}" unless col.valid?
          end
        end

        private

        def parse_columns(columns_data)
          return [] if columns_data.blank?

          columns_data.map { |col_data| ColumnDefinition.from_hash(col_data) }
        end
      end
    end
  end
end
