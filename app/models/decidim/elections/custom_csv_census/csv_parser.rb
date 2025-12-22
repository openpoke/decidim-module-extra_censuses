# frozen_string_literal: true

require "csv"

module Decidim
  module Elections
    module CustomCsvCensus
      # Utility for parsing CSV files.
      module CsvParser
        SEPARATOR = ";"

        module_function

        def parse(file)
          rows = []
          headers = []
          CSV.foreach(file, headers: true, col_sep: SEPARATOR, encoding: "BOM|UTF-8") do |row|
            headers = row.headers if headers.empty?
            rows << row.to_h
          end
          [rows, headers]
        end
      end
    end
  end
end
