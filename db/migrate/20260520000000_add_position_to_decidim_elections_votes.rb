# frozen_string_literal: true

class AddPositionToDecidimElectionsVotes < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_elections_votes, :position, :integer
  end
end
