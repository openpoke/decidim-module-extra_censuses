# frozen_string_literal: true

module Decidim
  module Elections
    module Censuses
      # Form for voter authentication using custom CSV census.
      class CustomCsvForm < Decidim::Form
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

          query = election.census.users(election)

          column_definitions.each do |col|
            name = col["name"]
            value = census_data[name]
            next if value.blank?

            transformed = CustomCsvCensus::Types.transform(col["column_type"], value.to_s)
            query = query.where("data->>? = ?", name, transformed)
          end

          @census_user = query.first
        end

        def column_names
          @column_names ||= columns_config.map { |c| c["name"] }
        end

        def column_definitions
          @column_definitions ||= columns_config
        end

        private

        def columns_config
          @columns_config ||= election.census_settings&.dig("columns") || []
        end

        def data_in_census
          return if voter_uid.present?

          errors.add(:base, I18n.t("decidim.elections.censuses.custom_csv_form.invalid"))
        end
      end
    end
  end
end
