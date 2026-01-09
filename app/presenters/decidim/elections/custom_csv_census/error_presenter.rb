# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      # Formats CSV validation errors for display.
      class ErrorPresenter
        def initialize(error)
          @error = error
        end

        def message
          case @error[:type]
          when :csv_error
            I18n.t("activemodel.errors.models.custom_csv.attributes.file.malformed_csv", message: @error[:message])
          when :header_error
            I18n.t("activemodel.errors.models.custom_csv.attributes.file.#{@error[:error]}", columns: @error[:columns].join(", "))
          when :validation_error
            I18n.t("activemodel.errors.models.custom_csv.attributes.file.validation_error", row: @error[:row], column: @error[:column], error: @error[:error])
          else
            @error.to_s
          end
        end
      end
    end
  end
end
