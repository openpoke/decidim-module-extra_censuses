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

    # Palette for response option labels
    def self.label_colors
      {
        gray: { background: "#F6F8FA", foreground: "#4B5058", name: I18n.t("gray", scope: "activemodel.attributes.response_option_label.colors") },
        blue: { background: "#EBF9FF", foreground: "#0851A6", name: I18n.t("blue", scope: "activemodel.attributes.response_option_label.colors") },
        green: { background: "#E3FCE9", foreground: "#15602C", name: I18n.t("green", scope: "activemodel.attributes.response_option_label.colors") },
        yellow: { background: "#FFFCE5", foreground: "#9A6700", name: I18n.t("yellow", scope: "activemodel.attributes.response_option_label.colors") },
        orange: { background: "#FFF1E5", foreground: "#BC4C00", name: I18n.t("orange", scope: "activemodel.attributes.response_option_label.colors") },
        red: { background: "#FFEBE9", foreground: "#D1242F", name: I18n.t("red", scope: "activemodel.attributes.response_option_label.colors") },
        pink: { background: "#FFEFF7", foreground: "#BF3989", name: I18n.t("pink", scope: "activemodel.attributes.response_option_label.colors") },
        purple: { background: "#FBEFFF", foreground: "#8250DF", name: I18n.t("purple", scope: "activemodel.attributes.response_option_label.colors") }
      }
    end
  end
end
