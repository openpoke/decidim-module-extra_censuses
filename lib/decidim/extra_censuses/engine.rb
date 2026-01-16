# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module ExtraCensuses
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::ExtraCensuses

      initializer "decidim.extra_censuses.mount_routes" do
        Decidim::Elections::AdminEngine.routes.prepend do
          resources :elections, only: [] do
            resources :census_updates, only: [:index, :new, :create, :destroy], controller: "/decidim/elections/admin/census_updates"
          end
        end
      end

      initializer "decidim.extra_censuses.menu", after: "decidim_elections_admin.menu" do
        Decidim.menu :admin_elections_menu do |menu|
          next if @election.blank?

          show_tab = @election.census_manifest == "custom_csv" &&
                     @election.census_settings&.dig("columns").present?

          current_component_admin_proxy = Decidim::EngineRouter.admin_proxy(@election.component)

          menu.add_item :census_updates,
                        I18n.t("census_updates", scope: "decidim.admin.menu.elections_menu"),
                        current_component_admin_proxy.election_census_updates_path(@election),
                        position: 3.5,
                        if: show_tab,
                        active: is_active_link?(current_component_admin_proxy.election_census_updates_path(@election)),
                        icon_name: "file-list-3-line"
        end
      end

      initializer "decidim.extra_censuses.custom_csv_census", after: "decidim.elections.default_censuses" do
        next unless Decidim.const_defined?(:Elections)

        Decidim::Elections.census_registry.register(:custom_csv) do |manifest|
          manifest.admin_form = "Decidim::Elections::Admin::Censuses::CustomCsvForm"
          manifest.admin_form_partial = "decidim/elections/admin/censuses/custom_csv_form"
          manifest.voter_form = "Decidim::Elections::Censuses::CustomCsvForm"
          manifest.voter_form_partial = "decidim/elections/censuses/custom_csv_form"
          manifest.after_update_command = "Decidim::Elections::Admin::Censuses::CustomCsv"

          manifest.user_query do |election|
            Decidim::Elections::Voter.where(election: election)
          end
        end
      end

      initializer "decidim.extra_censuses.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      # Overrides and helpers
      config.to_prepare do
        Decidim::Elections::Admin::CensusController.include(Decidim::ExtraCensuses::CensusControllerOverride)
        Decidim::Elections::Admin::CensusController.helper(Decidim::Elections::Admin::Censuses::CustomCsvHelper)
      end
    end
  end
end
