# frozen_string_literal: true

module Decidim
  module Elections
    module CustomCsvCensus
      # Checks for duplicate census entries based on JSONB data fields.
      # Shared logic used by query, job, and form classes.
      module DuplicateChecker
        def self.exists?(election, census_data)
          return false if census_data.blank?

          query = election.voters
          census_data.each do |name, value|
            query = query.where("data->>? = ?", name, value)
          end
          query.exists?
        end
      end
    end
  end
end
