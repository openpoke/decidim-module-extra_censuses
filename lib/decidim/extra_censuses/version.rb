# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    VERSION = "0.2.0"
    DECIDIM_VERSION = { github: "openpoke/decidim", branch: "0.31-backports" }.freeze
    COMPAT_DECIDIM_VERSION = [">= 0.31.0", "< 0.32"].freeze

    def self.version
      VERSION
    end
  end
end
