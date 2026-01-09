# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Override module to customize CensusController behavior for custom_csv census.
    # Handles redirect logic when census configuration is saved without data.
    module CensusControllerOverride
      extend ActiveSupport::Concern

      included do
        # Override the update action to handle custom_csv redirect
        def update
          enforce_permission_to :update, :census, election: election

          @form = form(election.census.admin_form.constantize).from_params(params, election: election) if election.census.admin_form.present?

          Decidim::Elections::Admin::ProcessCensus.call(@form, election) do
            on(:ok) do
              if election.census&.name == :custom_csv && !election.census_ready?
                flash[:notice] = t("decidim.elections.admin.census.update.success_config_only")
                redirect_to election_census_path(election, manifest: election.census&.name)
              else
                flash[:notice] = t("decidim.elections.admin.census.update.success")
                redirect_to dashboard_election_path(election)
              end
            end
            on(:invalid) do
              flash[:alert] = t("decidim.elections.admin.census.update.error")
              render :edit, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end
