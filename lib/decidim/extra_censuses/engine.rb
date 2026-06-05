# frozen_string_literal: true

require "rails"
require "deface"
require "decidim/core"

module Decidim
  module ExtraCensuses
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::ExtraCensuses

      initializer "decidim.extra_censuses.mount_routes" do
        Decidim::Elections::AdminEngine.routes.prepend do
          resources :elections, only: [] do
            resources :response_option_labels, only: [:update], controller: "/decidim/elections/admin/response_option_labels"

            resources :census_updates, only: [:index, :new, :create, :destroy], controller: "/decidim/elections/admin/census_updates"

            resources :survey_imports, only: [:index, :new, :create], controller: "/decidim/elections/admin/survey_imports" do
              collection do
                post :import
                get :surveys
                get :questions
              end
            end
          end
        end
      end

      initializer "decidim.extra_censuses.menu", after: "decidim_elections_admin.menu" do
        Decidim.menu :admin_elections_menu do |menu|
          next if @election.blank?

          # Requires Election#editable? from openpoke/decidim 0.31-backports (upstream PR #15687).
          # On stock decidim 0.31.0 this method does not exist — replace with `!@election.published?`.
          show_tab = @election.census_manifest == "custom_csv" &&
                     @election.census_settings&.dig("columns").present? &&
                     @election.editable?

          current_component_admin_proxy = Decidim::EngineRouter.admin_proxy(@election.component)

          menu.add_item :census_updates,
                        I18n.t("census_updates", scope: "decidim.admin.menu.elections_menu"),
                        current_component_admin_proxy.election_census_updates_path(@election),
                        position: 3.5,
                        if: show_tab,
                        active: is_active_link?(current_component_admin_proxy.election_census_updates_path(@election)),
                        icon_name: "file-list-3-line"
        end
      end

      initializer "decidim.extra_censuses.custom_csv_census", after: "decidim.elections.default_censuses" do
        next unless Decidim.const_defined?(:Elections)

        Decidim::Elections.census_registry.register(:custom_csv) do |manifest|
          manifest.admin_form = "Decidim::Elections::Admin::Censuses::CustomCsvForm"
          manifest.admin_form_partial = "decidim/elections/admin/censuses/custom_csv_form"
          manifest.voter_form = "Decidim::Elections::Censuses::CustomCsvForm"
          manifest.voter_form_partial = "decidim/elections/censuses/custom_csv_form"
          manifest.after_update_command = "Decidim::Elections::Admin::Censuses::CustomCsv"

          manifest.user_query do |election|
            Decidim::Elections::Voter.where(election: election)
          end
        end
      end

      initializer "decidim.extra_censuses.voting_methods", after: "decidim.elections.default_censuses" do
        next unless Decidim.module_installed?(:elections)

        Decidim::ExtraCensuses.voting_method_registry.register(:borda) do |manifest|
          manifest.model_concern = "Decidim::ExtraCensuses::VotingMethods::Borda::QuestionFields"
          manifest.form_fields = "Decidim::ExtraCensuses::VotingMethods::Borda::QuestionFormFields"
          manifest.question_validator = "Decidim::ExtraCensuses::VotingMethods::Borda::QuestionValidator"
          manifest.responses_parser = "Decidim::ExtraCensuses::VotingMethods::Borda::ResponsesParser"
          manifest.results_calculator = "Decidim::ExtraCensuses::BordaScorer"
          manifest.config_chips = "Decidim::ExtraCensuses::VotingMethods::Borda::ConfigChipsPresenter"
          manifest.stimulus_controller = "voter-borda"
        end
      end

      initializer "decidim.extra_censuses.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim.extra_censuses.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("app/cells", root)
      end

      # Overrides and helpers
      config.to_prepare do
        Decidim::Elections::Admin::CensusController.include(Decidim::ExtraCensuses::CensusControllerOverride)
        Decidim::Elections::Admin::CensusController.helper(Decidim::Elections::Admin::Censuses::CustomCsvHelper)

        Decidim::Elections::Question.include(Decidim::ExtraCensuses::QuestionOverride)
        Decidim::Elections::ResponseOption.include(Decidim::ExtraCensuses::ResponseOptionOverride)
        Decidim::Elections::ElectionPresenter.include(Decidim::ExtraCensuses::ElectionPresenterOverride)
        Decidim::Elections::Admin::ResponseOptionForm.include(Decidim::ExtraCensuses::ResponseOptionFormOverride)
        Decidim::Elections::Admin::QuestionForm.include(Decidim::ExtraCensuses::QuestionFormOverride)

        Decidim::ExtraCensuses.voting_method_registry.manifests.each do |manifest|
          Decidim::Elections::Question.include(manifest.model_concern.constantize) if manifest.model_concern.present?
          Decidim::Elections::Admin::QuestionForm.include(manifest.form_fields.constantize) if manifest.form_fields.present?
        end

        Decidim::Elections::Admin::UpdateQuestions.include(Decidim::ExtraCensuses::UpdateQuestionsOverride)
        Decidim::Elections::CastVotes.include(Decidim::ExtraCensuses::CastVotesOverride)
        Decidim::Elections::VotesController.include(Decidim::ExtraCensuses::ChoicesRangeCheck)
        Decidim::Elections::PerQuestionVotesController.include(Decidim::ExtraCensuses::ChoicesRangeCheck)
        Decidim::Elections::ApplicationHelper.include(Decidim::ExtraCensuses::ApplicationHelperOverride)

        Decidim::Elections::VotesController.helper(Decidim::ExtraCensuses::GroupedResponseOptionsHelper)
        Decidim::Elections::PerQuestionVotesController.helper(Decidim::ExtraCensuses::GroupedResponseOptionsHelper)
        Decidim::Elections::VotesController.helper(Decidim::ExtraCensuses::BordaVotingHelper)
        Decidim::Elections::PerQuestionVotesController.helper(Decidim::ExtraCensuses::BordaVotingHelper)
        Decidim::Elections::VotesController.helper(Decidim::ExtraCensuses::VotingMethodCellHelper)
        Decidim::Elections::PerQuestionVotesController.helper(Decidim::ExtraCensuses::VotingMethodCellHelper)
        Decidim::Elections::Admin::QuestionsController.helper(Decidim::ExtraCensuses::GroupedResponseOptionsHelper)
        Decidim::Elections::Admin::ElectionsController.helper(Decidim::ExtraCensuses::GroupedResponseOptionsHelper)
        Decidim::Elections::Admin::ElectionsController.helper(Decidim::ExtraCensuses::ResultsHelper)
        Decidim::Elections::Admin::ElectionsController.helper(Decidim::ExtraCensuses::AdminQuestionMetaHelper)
        Decidim::Elections::ElectionsController.helper(Decidim::ExtraCensuses::GroupedResponseOptionsHelper)
        Decidim::Elections::ElectionsController.helper(Decidim::ExtraCensuses::ResultsHelper)
      end
    end
  end
end
