# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Override for Decidim::Elections::VotesController.
    # Adds min_choices validation to #update, so that both min and max
    # constraints are enforced when the user proceeds to the next question.
    module VotesControllerOverride
      extend ActiveSupport::Concern

      included do
        include Decidim::ExtraCensuses::ChoicesRangeCheck

        def update
          enforce_permission_to(:create, :vote, election:)

          response_ids = Array(params.dig(:response, question.id.to_s)).compact

          if out_of_choices_range?(response_ids.size)
            flash.now[:alert] = choices_range_alert_message
            render :show
            return
          end

          votes_buffer[question.id.to_s] = params.dig(:response, question.id.to_s)
          redirect_to next_vote_step_path
        end
      end
    end
  end
end
