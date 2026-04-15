# frozen_string_literal: true

class AddSettingsToDecidimElectionsQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_elections_questions, :settings, :jsonb, default: {}, null: false
  end
end
