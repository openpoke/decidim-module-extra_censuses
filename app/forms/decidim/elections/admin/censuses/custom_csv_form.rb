# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      module Censuses
        # Form for Custom CSV census configuration and file upload.
        class CustomCsvForm < Decidim::Form
          include Decidim::HasUploadValidations
          include CustomCsvCensus::ColumnAccessors

          delegate :election, to: :context, allow_nil: true

          attribute :file, Decidim::Attributes::Blob
          attribute :columns, [Hash]
          attribute :remove_all, Decidim::AttributeObject::Model::Boolean, default: false

          validates :file, file_content_type: { allow: %w(text/csv text/plain) }, if: :file?

          validate :validate_columns, if: :columns?
          validate :validate_csv_data, if: :file?
          validate :validate_no_voters_for_changes

          def census_settings
            cols = columns? ? normalize_columns(columns) : persisted_columns
            { "columns" => cols }
          end

          def data
            csv_data&.data || []
          end

          def effective_columns
            columns.presence || persisted_columns
          end

          def csv_data
            return @csv_data if defined?(@csv_data)
            return nil if file.blank?

            file_io = StringIO.new(file.download)
            @csv_data = CustomCsvCensus::Data.new(file_io, effective_columns)
          rescue CSV::MalformedCSVError
            errors.add(:file, :malformed)
            @csv_data = nil
          end

          def columns? = columns.present?

          def available_column_types = Decidim::ExtraCensuses.column_types

          def file? = file.present?

          def has_voters? = election&.voters&.exists?

          def persisted_columns = election&.census_settings&.dig("columns") || []

          private

          def validate_columns
            columns.each_with_index do |col, index|
              errors.add(:columns, :blank_name, index: index + 1) if column_name(col).blank?
              errors.add(:columns, :invalid_type, index: index + 1, type: column_type(col)) unless available_column_types.include?(column_type(col))
            end
          end

          def validate_csv_data
            return errors.add(:file, :columns_not_configured) if effective_columns.blank?
            return if csv_data&.valid?

            csv_data&.error_messages&.each { |msg| errors.add(:file, msg) }
          end

          def validate_no_voters_for_changes
            return unless has_voters?
            return if remove_all

            errors.add(:file, :voters_exist) if file?
            errors.add(:columns, :voters_exist) if columns?
          end
        end
      end
    end
  end
end
