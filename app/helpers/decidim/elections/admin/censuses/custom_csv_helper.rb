# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      module Censuses
        # Helper methods for Custom CSV census views.
        module CustomCsvHelper
          def custom_csv_column_types_config
            Decidim::ExtraCensuses.column_types.index_with do |type|
              t("decidim.elections.admin.censuses.custom_csv_form.column_types.#{type}")
            end
          end

          def custom_csv_column_types_options
            Decidim::ExtraCensuses.column_types.map do |type|
              [t("decidim.elections.admin.censuses.custom_csv_form.column_types.#{type}"), type]
            end
          end

          def format_custom_csv_columns(columns)
            columns.map { |col| format_custom_csv_column(col) }.join(", ")
          end

          def format_custom_csv_column(column)
            name = column["name"] || column[:name]
            type = column["column_type"] || column[:column_type]
            type_label = t(
              "decidim.elections.admin.censuses.custom_csv_form.column_types.#{type}",
              default: type
            )

            "#{name} (#{type_label})"
          end

          def custom_csv_js_config(form)
            { formPrefix: form.object_name }
          end
        end
      end
    end
  end
end
