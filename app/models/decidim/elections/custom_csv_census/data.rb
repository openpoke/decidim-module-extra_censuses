# frozen_string_literal: true

require "csv"

module Decidim
  module Elections
    module CustomCsvCensus
      # This class parses CSV data for the custom census type.
      # It handles dynamic columns defined by the admin, applies transformations,
      # validates data according to column types, and removes duplicates.
      class Data
        attr_reader :file, :column_config, :errors, :duplicates_removed

        def initialize(file, column_config = nil)
          @file = file
          @column_config = column_config || ColumnConfig.new([])
          @errors = []
          @duplicates_removed = 0
        end

        def data
          @data ||= parse_and_process_csv
        end

        def valid?
          data
          @errors.empty?
        end

        def headers
          @headers ||= []
        end

        def error_messages
          errors.map { |error| format_error(error) }
        end

        private

        def format_error(error)
          case error[:type]
          when :csv_error
            I18n.t("activemodel.errors.models.custom_csv.attributes.file.malformed_csv", message: error[:message])
          when :header_error
            key = error[:error] == :missing_columns ? :missing_columns : :extra_columns
            I18n.t("activemodel.errors.models.custom_csv.attributes.file.#{key}", columns: error[:columns].join(", "))
          when :validation_error
            I18n.t("activemodel.errors.models.custom_csv.attributes.file.validation_error",
                   row: error[:row], column: error[:column], error: error[:error])
          else
            error.to_s
          end
        end

        def parse_and_process_csv
          return [] if file.blank?

          rows = parse_csv
          return [] if rows.empty? || @errors.any?
          return [] unless validate_headers

          rows = validate_rows(rows)
          return [] if @errors.any?

          rows = transform_rows(rows)
          remove_duplicates(rows)
        end

        def validate_headers
          return true if column_config.columns.empty?

          expected_columns = column_config.column_names
          actual_columns = @headers.compact

          missing = expected_columns - actual_columns
          extra = actual_columns - expected_columns

          if missing.any?
            @errors << {
              type: :header_error,
              error: :missing_columns,
              columns: missing
            }
          end

          if extra.any?
            @errors << {
              type: :header_error,
              error: :extra_columns,
              columns: extra
            }
          end

          @errors.empty?
        end

        def parse_csv
          rows = []
          @headers = []
          CSV.foreach(file, headers: true, col_sep: detect_separator, encoding: "BOM|UTF-8") do |row|
            @headers = row.headers if @headers.empty?
            rows << row.to_h
          end
          rows
        rescue CSV::MalformedCSVError => e
          @errors << { type: :csv_error, message: e.message }
          []
        end

        def transform_rows(rows)
          return rows if column_config.columns.empty?

          rows.map do |row|
            transformed = {}
            row.each do |key, value|
              column = column_config.find_column(key)
              transformed[key] = column ? column.transform(value) : value
            end
            transformed
          end
        end

        def validate_rows(rows)
          return rows if column_config.columns.empty?

          valid_rows = []
          rows.each_with_index do |row, index|
            row_errors = validate_row(row, index)
            if row_errors.empty?
              valid_rows << row
            else
              @errors.concat(row_errors)
            end
          end
          valid_rows
        end

        def validate_row(row, index)
          row_errors = []
          row.each do |key, value|
            column = column_config.find_column(key)
            next unless column

            result = column.validate_value(value)
            next if result[:valid]

            row_errors << {
              type: :validation_error,
              row: index + 2, # +2 because of 0-index and header row
              column: key,
              error: result[:error],
              value: value
            }
          end
          row_errors
        end

        def remove_duplicates(rows)
          seen = Set.new
          unique_rows = []

          rows.each do |row|
            key = row.values.map(&:to_s).join("|")

            if seen.include?(key)
              @duplicates_removed += 1
            else
              seen.add(key)
              unique_rows << row
            end
          end

          unique_rows
        end

        def detect_separator
          file.rewind if file.respond_to?(:rewind)
          first_line = file.readline
          file.rewind if file.respond_to?(:rewind)
          %W(; , \t).max_by { |sep| first_line.count(sep) }
        rescue StandardError
          file.rewind if file.respond_to?(:rewind)
          ";"
        end
      end
    end
  end
end
