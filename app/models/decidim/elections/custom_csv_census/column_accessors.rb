# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      # Shared methods for accessing column attributes from hash with symbol or string keys.
      module ColumnAccessors
        def column_name(col) = col["name"] || col[:name]

        def column_type(col) = col["column_type"] || col[:column_type] || "free_text"

        def normalize_column(col)
          { "name" => column_name(col)&.strip, "column_type" => column_type(col) }
        end

        def normalize_columns(list)
          return [] if list.blank?

          list.filter_map { |col| normalize_column(col) if col.is_a?(Hash) }
        end
      end
    end
  end
end
