# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Resolves a voting method's view partial by convention from the method name,
    # so a new method only drops its own folder of partials with no deface edits.
    module VotingMethodPartialsHelper
      extend ActiveSupport::Concern

      included do
        def voting_method_partial(question, surface)
          partial = "decidim/extra_censuses/voting_methods/#{question.voting_method}/#{surface}"
          partial if lookup_context.exists?(partial, [], true)
        end
      end
    end
  end
end
