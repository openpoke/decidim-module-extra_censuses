# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Resolves a voting method's view cell by convention from the method name, so
    # a new method only drops its own cell with no deface edits.
    module VotingMethodCellHelper
      extend ActiveSupport::Concern

      included do
        def voting_method_cell(question, surface, context = {})
          return unless "Decidim::ExtraCensuses::VotingMethods::#{question.voting_method.to_s.camelize}::#{surface.camelize}Cell".safe_constantize

          cell("decidim/extra_censuses/voting_methods/#{question.voting_method}/#{surface}", question, context:)
        end
      end
    end
  end
end
