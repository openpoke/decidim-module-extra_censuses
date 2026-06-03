# frozen_string_literal: true

require "decidim/extra_censuses/engine"
require "decidim/extra_censuses/version"

module Decidim
  # This namespace holds the logic of the `ExtraCensuses` module.
  # It provides a custom CSV census type for Elections.
  module ExtraCensuses
    include ActiveSupport::Configurable

    autoload :VotingMethodManifest, "decidim/extra_censuses/voting_method_manifest"

    # Available column types for Custom CSV census.
    # Each type defines how values are transformed and validated.
    config_accessor :column_types do
      %w(alphanumeric free_text text_trim date number)
    end

    def self.voting_method_registry
      @voting_method_registry ||= Decidim::ManifestRegistry.new("extra_censuses/voting_method")
    end
  end
end
