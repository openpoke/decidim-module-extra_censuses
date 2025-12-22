# frozen_string_literal: true

require "csv"

module Decidim
  module Elections
    module CustomCsvCensus
      # Utility for parsing CSV files with auto-detected separators.
      module CsvParser
        SEPARATORS = %W(; , \t).freeze

        module_function

        def parse(file)
          rows = []
          headers = []
          CSV.foreach(file, headers: true, col_sep: detect_separator(file), encoding: "BOM|UTF-8") do |row|
            headers = row.headers if headers.empty?
            rows << row.to_h
          end
          [rows, headers]
        end

        def detect_separator(file)
          file.rewind if file.respond_to?(:rewind)
          line = file.readline
          file.rewind if file.respond_to?(:rewind)
          SEPARATORS.max_by { |s| line.count(s) }
        rescue StandardError
          file.rewind if file.respond_to?(:rewind)
          Decidim.default_csv_col_sep
        end
      end
    end
  end
end
