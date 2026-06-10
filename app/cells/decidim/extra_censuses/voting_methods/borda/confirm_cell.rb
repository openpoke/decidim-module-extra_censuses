# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        class ConfirmCell < Decidim::ViewModel
          include Decidim::ExtraCensuses::GroupedResponseOptionsHelper

          def show
            render
          end

          private

          def selected_options
            context[:selected] || []
          end

          def response_groups
            confirm_response_groups(model, selected_options)
          end

          # `selected_options.size` is the full ranked count, so start_from_min
          # points match even when `options` is just one group.
          def confirm_rows(options)
            options.sort_by { |option| positions[option.id.to_s].to_i }.map do |option|
              rank = positions[option.id.to_s].to_i
              [option, rank, model.borda_points(rank, selected_options.size)]
            end
          end

          def positions
            @positions ||= BufferedPositions.lookup(model, context)
          end
        end
      end
    end
  end
end
