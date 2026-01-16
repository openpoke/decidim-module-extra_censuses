# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Command to import census entries from survey responses.
      # Imports all valid responses in background.
      class ImportFromSurvey < Decidim::Command
        def initialize(election)
          @election = election
        end

        def call
          responses = SurveyResponsesForImport.new(election).query
          @valid_responses = responses.select { |r| r[:status] == :valid }

          return broadcast(:invalid) if valid_responses.empty?

          enqueue_job
          broadcast(:ok, valid_responses.count)
        end

        private

        attr_reader :election, :valid_responses

        def enqueue_job
          Decidim::ExtraCensuses::ImportFromSurveyJob.perform_later(
            election.id,
            valid_responses.map { |r| r[:census_data] }
          )
        end
      end
    end
  end
end
