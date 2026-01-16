# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Command to create a new census entry (voter).
      class CreateCensusEntry < Decidim::Commands::UpdateResource
        def attributes
          {}
        end

        def run_after_hooks
          @voter = Decidim::Elections::Voter.create!(
            election: resource,
            data: form.transformed_data
          )
        end
      end
    end
  end
end
