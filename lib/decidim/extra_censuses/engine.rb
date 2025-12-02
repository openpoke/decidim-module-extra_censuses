# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module ExtraCensuses
    # This is the engine that runs on the public interface of extra_censuses.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::ExtraCensuses

      routes do
        # Add engine routes here
        # resources :extra_censuses
        # root to: "extra_censuses#index"
      end

      initializer "ExtraCensuses.shakapacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "ExtraCensuses.data_migrate", after: "decidim_core.data_migrate" do
        DataMigrate.configure do |config|
          config.data_migrations_path << root.join("db/data").to_s
        end
      end
    end
  end
end
