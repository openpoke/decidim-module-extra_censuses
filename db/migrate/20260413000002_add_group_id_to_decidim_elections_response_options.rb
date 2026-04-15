# frozen_string_literal: true

class AddGroupIdToDecidimElectionsResponseOptions < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_elections_response_options, :group_id, :string
  end
end
