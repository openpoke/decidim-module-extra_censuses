# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        # Voter-facing ranked (BORDA) response options. The flat `show` state
        # renders every option plus the status counter; `option` and `status` are
        # exposed so the grouped ballot reuses the same per-option/status rendering.
        class ResponseOptionsCell < Decidim::ViewModel
          def show
            render
          end

          def option(option)
            @option = option
            render :option
          end

          def status
            render :status
          end

          private

          def positions
            @positions ||= Decidim::ExtraCensuses::VotingMethods::Borda::BufferedPositions.new(
              votes_buffer: context[:votes_buffer] || {},
              voter_uid: context[:voter_uid],
              question: model
            ).to_h
          end

          def response_position(option)
            positions[option.id.to_s].presence&.to_i
          end

          # Labels reflect the scoring scale at the maximum ballot size; under
          # start_from_min the Stimulus controller recomputes them per k.
          def position_options
            max = model.max_votable_options
            (1..max).map { |pos| [position_label(pos, max), pos] }
          end

          def position_label(position, ballot_size)
            t("decidim.extra_censuses.elections.votes.borda.position_label",
              ordinal: ActiveSupport::Inflector.ordinalize(position),
              count: model.borda_points(position, ballot_size))
          end
        end
      end
    end
  end
end
