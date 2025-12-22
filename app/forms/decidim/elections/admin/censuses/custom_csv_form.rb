# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      module Censuses
        # Form for Custom CSV census configuration and file upload.
        class CustomCsvForm < Decidim::Form
          include Decidim::HasUploadValidations

          delegate :election, to: :context, allow_nil: true

          attribute :file, Decidim::Attributes::Blob
          attribute :columns, [Hash]
          attribute :columns_submitted, Decidim::AttributeObject::Model::Boolean, default: false
          attribute :remove_all, Decidim::AttributeObject::Model::Boolean, default: false

          validates :file, file_content_type: { allow: %w(text/csv text/plain) }, if: :file?

          validate :validate_columns, if: :configuring_columns?
          validate :validate_csv_data, if: :file?
          validate :validate_no_voters_for_changes

          def census_settings
            return { "columns" => saved_columns } unless columns_submitted?

            { "columns" => normalize_columns }
          end

          def data
            csv_data&.data || []
          end

          def csv_data
            return @csv_data if defined?(@csv_data)
            return nil if file.blank?

            file_io = StringIO.new(file.download)
            @csv_data = CustomCsvCensus::Data.new(file_io, column_config)
          rescue CSV::MalformedCSVError
            errors.add(:file, :malformed)
            @csv_data = nil
          end

          def column_config
            @column_config ||= CustomCsvCensus::ColumnConfig.new(effective_columns)
          end

          def effective_columns
            columns.presence || saved_columns
          end

          def saved_columns
            election&.census_settings&.dig("columns") || []
          end

          def columns_configured?
            saved_columns.present?
          end

          def available_column_types
            Decidim::ExtraCensuses.column_types
          end

          def file?
            file.present?
          end

          def configuring_columns?
            columns_submitted? && !file?
          end

          def columns_submitted?
            columns_submitted == true
          end

          def has_voters?
            election&.voters&.any?
          end

          private

          def normalize_columns
            columns.map do |col|
              {
                "name" => col[:name] || col["name"],
                "column_type" => col[:column_type] || col["column_type"] || "free_text"
              }
            end
          end

          def validate_columns
            columns.each_with_index do |col, index|
              name = col[:name] || col["name"]
              column_type = col[:column_type] || col["column_type"]

              errors.add(:columns, :blank_name, index: index + 1) if name.blank?
              errors.add(:columns, :invalid_type, index: index + 1, type: column_type) unless available_column_types.include?(column_type)
            end
          end

          def validate_csv_data
            return errors.add(:file, :columns_not_configured) unless columns_configured?
            return if csv_data&.valid?

            csv_data&.error_messages&.each { |msg| errors.add(:file, msg) }
          end

          def validate_no_voters_for_changes
            return unless has_voters?
            return if remove_all?

            errors.add(:file, :voters_exist) if file?
            errors.add(:columns, :voters_exist) if columns_submitted?
          end

          def remove_all?
            remove_all == true
          end
        end
      end
    end
  end
end
