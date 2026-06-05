# frozen_string_literal: true

class AddSettingsToDecidimElectionsResponseOptions < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_elections_response_options, :settings, :jsonb, default: {}, null: false
  end
end
