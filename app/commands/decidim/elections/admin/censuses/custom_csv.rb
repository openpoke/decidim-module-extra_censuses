# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      module Censuses
        # A command with the business logic to create census data for an
        # election using custom CSV with configurable columns.
        class CustomCsv < Decidim::Command
          def initialize(form, election)
            @form = form
            @election = election
          end

          # Executes the command. Broadcasts these events:
          # - :ok when everything is valid
          # - :invalid when the form was not valid and could not proceed
          #
          # Returns nothing.
          def call
            return broadcast(:invalid) if @form.invalid?
            return broadcast(:invalid) if @form.remove_all && @election.census.blank?

            if @form.remove_all
              @election.voters.delete_all
              return broadcast(:ok)
            end

            return broadcast(:ok) if @form.file.blank?

            rows = @form.data
            return broadcast(:invalid) if rows.blank?

            Decidim::Elections::Voter.bulk_insert(@election, rows)
            broadcast(:ok)
          end
        end
      end
    end
  end
end
