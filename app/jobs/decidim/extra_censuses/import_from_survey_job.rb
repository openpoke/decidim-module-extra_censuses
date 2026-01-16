# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Job to import census entries from survey responses in background.
    class ImportFromSurveyJob < Decidim::ApplicationJob
      queue_as :default

      def perform(election_id, census_data_list)
        election = Decidim::Elections::Election.find(election_id)

        imported_count = 0

        ActiveRecord::Base.transaction do
          census_data_list.each do |census_data|
            next if duplicate_exists?(election, census_data)

            Decidim::Elections::Voter.create!(
              election: election,
              data: census_data
            )
            imported_count += 1
          end
        end

        Rails.logger.info("ImportFromSurveyJob completed: #{imported_count} entries imported for election #{election_id}")
      end

      private

      def duplicate_exists?(election, census_data)
        Decidim::Elections::CustomCsvCensus::DuplicateChecker.exists?(election, census_data)
      end
    end
  end
end
