# frozen_string_literal: true

class AddMinChoicesToDecidimElectionsQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_elections_questions, :min_choices, :integer
  end
end
