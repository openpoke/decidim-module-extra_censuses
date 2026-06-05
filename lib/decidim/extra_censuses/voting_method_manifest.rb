# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    class VotingMethodManifest
      include ActiveModel::Model
      include Decidim::AttributeObject::Model

      attribute :name, Symbol
      attribute :model_concern, String, default: nil
      attribute :form_fields, String, default: nil
      attribute :question_validator, String, default: nil
      attribute :responses_parser, String, default: nil
      attribute :results_calculator, String, default: nil
      attribute :response_options_partial, String, default: nil
      attribute :confirm_partial, String, default: nil
      attribute :public_results_partial, String, default: nil
      attribute :admin_results_partial, String, default: nil
      attribute :stimulus_controller, String, default: nil
      attribute :i18n_scope, String, default: nil

      validates :name, presence: true

      def label
        I18n.t("#{i18n_scope || "decidim.extra_censuses.voting_methods.#{name}"}.label", default: name.to_s.humanize)
      end

      def computes_results?
        results_calculator.present?
      end

      def results_calculator_for(question)
        return unless computes_results?

        results_calculator.constantize.new(question)
      end
    end
  end
end
