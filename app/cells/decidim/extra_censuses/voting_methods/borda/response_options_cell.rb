# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        class ResponseOptionsCell < Decidim::ViewModel
          include Decidim::ExtraCensuses::GroupedResponseOptionsHelper

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
            @positions ||= BufferedPositions.lookup(model, context)
          end

          # Raw (uninterpolated) i18n templates fed to the Stimulus controller, which
          # substitutes %{position} / %{count} client-side as the number of ranked options changes.
          def label_one_template
            t("decidim.extra_censuses.elections.votes.borda.position_label", position: "%{position}", count: 1)
          end

          def label_other_template
            t("decidim.extra_censuses.elections.votes.borda.position_label", position: "%{position}", count: "%{count}")
          end

          def counter_template
            t("decidim.extra_censuses.elections.votes.borda.selected_counter", count: "%{count}", max: "%{max}")
          end

          def response_position(option)
            positions[option.id.to_s].presence&.to_i
          end

          # Labels reflect the scoring scale at the maximum number of selectable options;
          # under start_from_min the Stimulus controller recomputes them as the voter ranks.
          def position_options
            max = model.max_votable_options
            (1..max).map { |pos| [position_label(pos, max), pos] }
          end

          def position_label(position, ranked_options_count)
            t("decidim.extra_censuses.elections.votes.borda.position_label",
              position:,
              count: model.borda_points(position, ranked_options_count))
          end
        end
      end
    end
  end
end
