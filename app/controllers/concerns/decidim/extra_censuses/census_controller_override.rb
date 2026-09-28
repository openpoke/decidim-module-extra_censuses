# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Redirects a saved-but-empty custom_csv census back to its config page
    # instead of the dashboard.
    module CensusControllerOverride
      extend ActiveSupport::Concern

      included do
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
