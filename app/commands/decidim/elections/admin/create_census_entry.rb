# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Command to create a new census entry (voter).
      class CreateCensusEntry < Decidim::Command
        def initialize(form, election, current_user)
          @form = form
          @election = election
          @current_user = current_user
        end

        def call
          return broadcast(:invalid) if form.invalid?

          create_voter

          broadcast(:ok, @voter)
        end

        private

        attr_reader :form, :election, :current_user

        def create_voter
          @voter = Decidim.traceability.create!(
            Decidim::Elections::Voter,
            current_user,
            election: election,
            data: form.transformed_data
          )
        end
      end
    end
  end
end
