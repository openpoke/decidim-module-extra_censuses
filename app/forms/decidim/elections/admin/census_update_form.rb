# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Form for adding a new census entry.
      class CensusUpdateForm < Decidim::Form
        mimic :census_update

        attribute :data, Hash

        validate :all_columns_present
        validate :voter_not_exists

        def election
          @election ||= context[:election]
        end

        def column_definitions
          @column_definitions ||= election&.census_settings&.dig("columns") || []
        end

        def transformed_data
          @transformed_data ||= column_definitions.each_with_object({}) do |col, hash|
            name = col["name"]
            value = data_value(name)
            next if value.blank?

            hash[name] = CustomCsvCensus::Types.transform(col["column_type"], value.to_s)
          end
        end

        private

        def data_value(name)
          data[name.to_sym] || data[name]
        end

        def all_columns_present
          column_definitions.each do |col|
            name = col["name"]
            value = data_value(name)
            errors.add(:data, I18n.t("errors.blank_column", column: name, scope: "decidim.elections.admin.census_updates")) if value.blank?
          end
        end

        def voter_not_exists
          return if transformed_data.blank?

          query = Decidim::Elections::Voter.where(election: election)
          transformed_data.each do |name, value|
            query = query.where("data->>? = ?", name, value)
          end

          errors.add(:base, I18n.t("errors.already_exists", scope: "decidim.elections.admin.census_updates")) if query.exists?
        end
      end
    end
  end
end
