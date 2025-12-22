# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      module Censuses
        # Helper methods for Custom CSV census views.
        module CustomCsvHelper
          include CustomCsvCensus::ColumnAccessors

          def custom_csv_column_types_options
            Decidim::ExtraCensuses.column_types.map do |type|
              [t("decidim.elections.admin.censuses.custom_csv_form.column_types.#{type}"), type]
            end
          end

          def format_custom_csv_columns(columns)
            columns.map { |col| format_custom_csv_column(col) }.join(", ")
          end

          def format_custom_csv_column(column)
            type_label = t(
              "decidim.elections.admin.censuses.custom_csv_form.column_types.#{column_type(column)}",
              default: column_type(column)
            )

            "#{column_name(column)} (#{type_label})"
          end
        end
      end
    end
  end
end
