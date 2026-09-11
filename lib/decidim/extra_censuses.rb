# frozen_string_literal: true

require "decidim/extra_censuses/engine"
require "decidim/extra_censuses/version"

module Decidim
  # This namespace holds the logic of the `ExtraCensuses` module.
  # It provides a custom CSV census type for Elections.
  module ExtraCensuses
    # Available column types for Custom CSV census.
    # Each type defines how values are transformed and validated.
    mattr_accessor :column_types, default: %w(alphanumeric free_text text_trim date number)
  end
end
