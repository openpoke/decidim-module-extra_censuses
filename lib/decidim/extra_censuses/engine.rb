# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module ExtraCensuses
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::ExtraCensuses

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

      initializer "decidim.extra_censuses.helpers" do
        config.to_prepare do
          Decidim::Elections::Admin::CensusController.helper(
            Decidim::Elections::Admin::Censuses::CustomCsvHelper
          )
        end
      end
    end
  end
end
