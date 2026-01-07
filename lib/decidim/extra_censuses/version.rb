# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    VERSION = "0.1.0"
    DECIDIM_VERSION = "0.31.0"
    COMPAT_DECIDIM_VERSION = [">= 0.31.0", "< 0.32"].freeze

    def self.version
      VERSION
    end
  end
end
