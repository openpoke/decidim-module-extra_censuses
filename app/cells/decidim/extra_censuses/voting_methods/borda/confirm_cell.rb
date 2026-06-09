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
            options
              .map { |option| [option, positions[option.id.to_s].to_i] }
              .sort_by { |_option, rank| rank }
              .map { |option, rank| [option, rank, model.borda_points(rank, selected_options.size)] }
          end

          def positions
            @positions ||= Decidim::ExtraCensuses::VotingMethods::Borda::BufferedPositions.new(
              votes_buffer: context[:votes_buffer] || {},
              voter_uid: context[:voter_uid],
              question: model
            ).to_h
          end
        end
      end
    end
  end
end
