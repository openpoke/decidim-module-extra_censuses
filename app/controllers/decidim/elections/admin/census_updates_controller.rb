# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Controller for managing census entries (voters) in custom CSV census.
      class CensusUpdatesController < Admin::ApplicationController
        include Decidim::Paginable

        helper_method :election, :identifier_column

        def index
          enforce_permission_to :edit, :census, election: election
          @voters = paginate(filtered_voters)
        end

        def new
          enforce_permission_to :update, :census, election: election
          @form = form(CensusUpdateForm).instance(election: election)
        end

        def create
          enforce_permission_to :update, :census, election: election
          @form = CensusUpdateForm.new(data: census_data_params).with_context(election: election, current_user: current_user)

          CreateCensusEntry.call(@form, election) do
            on(:ok) do
              flash[:notice] = I18n.t("create.success", scope: "decidim.elections.admin.census_updates")
              redirect_to election_census_updates_path(election)
            end
            on(:invalid) do
              flash.now[:alert] = I18n.t("create.error", scope: "decidim.elections.admin.census_updates")
              render :new, status: :unprocessable_entity
            end
          end
        end

        def destroy
          enforce_permission_to :update, :census, election: election
          voter = election.voters.find(params[:id])
          @form = CensusUpdateForm.new.with_context(election:, voter:, current_user:)

          DestroyCensusEntry.call(@form, election) do
            on(:ok) do
              flash[:notice] = I18n.t("destroy.success", scope: "decidim.elections.admin.census_updates")
              redirect_to election_census_updates_path(election)
            end
          end
        end

        private

        def election
          @election ||= Decidim::Elections::Election.where(component: current_component).find(params[:election_id])
        end

        def filtered_voters
          voters = election.voters.order(created_at: :desc)
          return voters if params[:q].blank?

          voters.where("data->>? ILIKE ?", identifier_column, "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%")
        end

        def identifier_column
          @identifier_column ||= election.census_settings&.dig("columns", 0, "name")
        end

        def census_data_params
          return {} if params[:data].blank?

          allowed_keys = election.census_settings&.dig("columns")&.map { |c| c["name"] } || []
          params.require(:data).permit(*allowed_keys).to_h
        end
      end
    end
  end
end
