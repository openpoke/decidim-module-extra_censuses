# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    VERSION = "0.3.0"
    DECIDIM_VERSION = "~> 0.32.0"
    COMPAT_DECIDIM_VERSION = [">= 0.32.0", "< 0.33"].freeze

    def self.version
      VERSION
    end
  end
end
