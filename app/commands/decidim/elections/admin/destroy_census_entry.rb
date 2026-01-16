# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Command to destroy a census entry (voter).
      class DestroyCensusEntry < Decidim::Commands::UpdateResource
        def invalid?
          form.voter.blank?
        end

        def attributes
          {}
        end

        def run_after_hooks
          form.voter.destroy!
        end
      end
    end
  end
end
