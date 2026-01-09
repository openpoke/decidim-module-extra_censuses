# frozen_string_literal: true

module Decidim
  module Elections
    module Censuses
      # Form for voter authentication using custom CSV census.
      class CustomCsvForm < Decidim::Form
        include CustomCsvCensus::ColumnAccessors

        mimic :census_data

        attribute :census_data, Hash

        validate :data_in_census

        def election
          @election ||= context.election
        end

        def voter_uid
          @voter_uid ||= census_user&.to_global_id&.to_s
        end

        def census_user
          return @census_user if defined?(@census_user)
          return @census_user = nil if census_data.blank?

          query = election.census.users(election)
          has_criteria = false

          # Build case-insensitive lookup for input data
          input_data_lower = census_data.transform_keys { |k| k.to_s.strip.downcase }

          column_definitions.each do |col|
            column_name = col["name"]
            value = input_data_lower[column_name&.downcase]
            next if value.blank?

            has_criteria = true
            transformed = CustomCsvCensus::Types.transform(col["column_type"], value.to_s)
            # Query using original column name (as stored in DB)
            query = query.where("data->>? = ?", column_name, transformed)
          end

          @census_user = has_criteria ? query.first : nil
        end

        def column_names
          @column_names ||= columns_config.map { |c| c["name"] }
        end

        def column_definitions
          @column_definitions ||= columns_config
        end

        private

        def columns_config
          @columns_config ||= normalize_columns(election.census_settings&.dig("columns") || [])
        end

        def data_in_census
          return if voter_uid.present?

          errors.add(:base, I18n.t("decidim.elections.censuses.custom_csv_form.invalid"))
        end
      end
    end
  end
end
