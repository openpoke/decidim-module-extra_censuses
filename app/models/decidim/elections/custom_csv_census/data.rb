# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      # Parses and processes CSV data for custom census.
      class Data
        include ColumnAccessors

        attr_reader :file, :columns, :errors, :duplicates_removed, :headers

        def initialize(file, columns = [])
          @file = file
          @columns = normalize_columns(columns)
          @columns_index = @columns.index_by { |c| c["name"]&.downcase }
          @errors = []
          @duplicates_removed = 0
          @headers = []
        end

        def data
          @data ||= process
        end

        def valid? = data.present? && errors.empty?

        def error_messages = errors.map { |e| ErrorPresenter.new(e).message }

        def column_names = @columns.map { |c| c["name"] }

        private

        def find_column(name) = @columns_index[name&.downcase]

        def process
          return [] if file.blank?

          rows, @headers = parse_csv
          return [] if rows.empty? || errors.any?
          return [] unless validate_headers

          rows = validate_rows(rows)
          return [] if errors.any?

          transform_and_deduplicate(rows)
        end

        def parse_csv
          CsvParser.parse(file)
        rescue CSV::MalformedCSVError => e
          @errors << { type: :csv_error, message: e.message }
          [[], []]
        end

        def validate_headers
          return true if columns.empty?

          column_names_lower = column_names.map(&:downcase)
          headers_lower = @headers.compact.map(&:downcase)

          missing = column_names.reject { |name| headers_lower.include?(name.downcase) }
          extra = @headers.compact.reject { |h| column_names_lower.include?(h.downcase) }

          @errors << { type: :header_error, error: :missing_columns, columns: missing } if missing.any?
          @errors << { type: :header_error, error: :extra_columns, columns: extra } if extra.any?
          errors.empty?
        end

        def validate_rows(rows)
          return rows if columns.empty?

          rows.each_with_index.filter_map do |row, idx|
            errs = validate_row(row, idx)
            errs.empty? ? row : (@errors.concat(errs) && nil)
          end
        end

        def validate_row(row, idx)
          row.filter_map do |key, val|
            col = find_column(key)
            next unless col && val.present?

            error = Types.validate(col["column_type"], val.to_s)
            { type: :validation_error, row: idx + 2, column: key, error: } if error
          end
        end

        def transform_and_deduplicate(rows)
          seen = Set.new
          rows.each_with_object([]) do |row, result|
            transformed = transform_row(row)
            seen.add?(transformed.values.hash) ? result << transformed : @duplicates_removed += 1
          end
        end

        def transform_row(row)
          row.to_h do |key, val|
            col = find_column(key.to_s)
            transformed = col && val ? Types.transform(col["column_type"], val.to_s) : val
            # Use a column name from config (not from CSV) for consistency
            column_name = col ? col["name"] : key.to_s
            [column_name, transformed]
          end
        end
      end
    end
  end
end
