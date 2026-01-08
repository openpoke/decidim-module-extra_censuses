# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Command to destroy a census entry (voter).
      class DestroyCensusEntry < Decidim::Command
        def initialize(voter, current_user)
          @voter = voter
          @current_user = current_user
        end

        def call
          destroy_voter

          broadcast(:ok)
        end

        private

        attr_reader :voter, :current_user

        def destroy_voter
          Decidim.traceability.perform_action!(
            :delete,
            voter,
            current_user
          ) do
            voter.destroy!
          end
        end
      end
    end
  end
end
