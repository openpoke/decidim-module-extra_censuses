# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Override for Decidim::Elections::PerQuestionVotesController.
    # Adds min_choices/max_choices range check to #update, so that the user
    # cannot cast a per-question vote with a selection outside the allowed range.
    module PerQuestionVotesControllerOverride
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

          requeue_following_questions
          votes_buffer[question.id.to_s] = response_ids
          Decidim::Elections::CastVotes.call(election, { question.id.to_s => response_ids }, voter_uid) do
            on(:ok) do
              session[:voter_uid] = voter_uid
              flash[:notice] = t("votes.cast.success", scope: "decidim.elections")
              redirect_to(**next_vote_step_action)
            end

            on(:invalid) do
              action = { action: :show, id: question }
              action = next_vote_step_action unless question.voting_enabled?

              flash[:alert] = t("votes.cast.invalid", scope: "decidim.elections")
              redirect_to(**action)
            end
          end
        end
      end
    end
  end
end
