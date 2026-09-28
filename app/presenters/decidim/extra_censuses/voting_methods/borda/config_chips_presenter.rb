# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        class ConfigChipsPresenter
          def chips(question, scope)
            [I18n.t("scoring_scale.#{question.scoring_scale}", scope:)]
          end
        end
      end
    end
  end
end
