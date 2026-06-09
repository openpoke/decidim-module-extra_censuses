# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      class ResponseOptionLabelsController < Admin::ApplicationController
        def update
          enforce_permission_to(:update, :response_option_label, resource: response_option.question)

          @form = form(ResponseOptionLabelForm).from_params(params)

          UpdateResponseOptionLabel.call(@form, response_option) do
            on(:ok) do
              flash[:notice] = I18n.t("update.success", scope: "decidim.elections.admin.response_option_labels")
              redirect_to dashboard_election_path(election)
            end
            on(:invalid) do
              flash[:alert] = I18n.t("update.invalid", scope: "decidim.elections.admin.response_option_labels")
              redirect_to dashboard_election_path(election)
            end
          end
        end

        private

        def response_option
          @response_option ||= response_options.find(params[:id])
        end

        def election
          @election ||= Decidim::Elections::Election.where(component: current_component).find(params[:election_id])
        end

        def response_options
          Decidim::Elections::ResponseOption.where(question: election.questions)
        end
      end
    end
  end
end
