# frozen_string_literal: true

require "csv"

module Decidim
  module Elections
    module CustomCsvCensus
      # Utility for parsing CSV files.
      module CsvParser
        def self.parse(file)
          table = CSV.read(file, headers: true, col_sep: Decidim.default_csv_col_sep, encoding: "BOM|UTF-8")
          headers = table.headers.map { |h| h&.strip }
          rows = table.map { |row| row.to_h.transform_keys { |k| k&.strip } }
          [rows, headers]
        end
      end
    end
  end
end
