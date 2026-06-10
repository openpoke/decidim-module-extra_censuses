# frozen_string_literal: true

require "spec_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
module Decidim::ExtraCensuses
  checksums = [
    {
      package: "decidim-elections",
      files: {
        # models
        "/app/models/decidim/elections/question.rb" => "5b8422f140ba46d959fbe979deefd223",
        "/app/models/decidim/elections/response_option.rb" => "e80df56ee6f6f1422f9d05fbd8205e95",
        # permissions
        "/app/permissions/decidim/elections/admin/permissions.rb" => "f906db775613a7f9722c5ca48efba86b",
        # forms
        "/app/forms/decidim/elections/admin/question_form.rb" => "df808ddabd28c135e45b6fe4df0325a7",
        "/app/forms/decidim/elections/admin/response_option_form.rb" => "18e78ccbc41f1fc8bbe8298bd6535fc3",
        # commands
        "/app/commands/decidim/elections/admin/update_questions.rb" => "2b64fc68a96bbd352becb311a8415eb0",
        "/app/commands/decidim/elections/cast_votes.rb" => "f14dc636a3cd3d182b7d48338c7c55c8",
        # presenters
        "/app/presenters/decidim/elections/election_presenter.rb" => "62961be51c941bf956214b78cd1a08be",
        # controllers
        "/app/controllers/decidim/elections/admin/census_controller.rb" => "f3a866fe5f69f378cf419a40304b97e0",
        "/app/controllers/decidim/elections/votes_controller.rb" => "53a611d2a456e2032b986a76cdcf6bf1",
        "/app/controllers/decidim/elections/per_question_votes_controller.rb" => "fa6a7d89d010bbe8faa02d3e89c94d43",
        # helpers
        "/app/helpers/decidim/elections/application_helper.rb" => "c299bc5843e4c3c361756b5fdf602237",
        # admin views
        "/app/views/decidim/elections/admin/dashboard/_questions.html.erb" => "a7dfda79d4d417d95a6d266083323fc5",
        "/app/views/decidim/elections/admin/dashboard/_questions_with_results.html.erb" => "d34c5f76445d444e9e28b2192d80d420",
        "/app/views/decidim/elections/admin/questions/_form.html.erb" => "3549d092d3e22920b1cb2c6c6c53b1cd",
        "/app/views/decidim/elections/admin/questions/_question.html.erb" => "c679c5aa57ed5307845c4ebb2737558d",
        "/app/views/decidim/elections/admin/questions/_response_option.html.erb" => "58cf226fd79cd547a5d1cf87ea7a3c22",
        "/app/views/decidim/elections/admin/elections/dashboard.html.erb" => "277897a8f93152d0ac6e0786150b2266",
        # public views
        "/app/views/decidim/elections/elections/show.html.erb" => "f08f1c9a72f0dc7b7c0e1acaa49841ca",
        "/app/views/decidim/elections/elections/_questions.html.erb" => "182f98be98b5f84d553978150507369c",
        "/app/views/decidim/elections/elections/_vote_results_option.html.erb" => "77e720856c3c8dc6beb709c97e7a1ad5",
        "/app/views/decidim/elections/elections/_vote_results_question.html.erb" => "449b5dcd8c2ea5a0d1d59d7cc5b315ae",
        "/app/views/decidim/elections/per_question_votes/show.html.erb" => "5b0cd91877704f8211307ed220006421",
        "/app/views/decidim/elections/votes/confirm.html.erb" => "569eef46e86ee445216fbb915c2c96ae",
        "/app/views/decidim/elections/votes/show.html.erb" => "a46c6a1392772a52ed5d8e11c05ad7ed"
      }
    }
  ]

  describe "Overriden files", type: :view do
    checksums.each do |item|
      # rubocop:disable Rails/DynamicFindBy
      spec = ::Gem::Specification.find_by_name(item[:package])
      # rubocop:enable Rails/DynamicFindBy
      item[:files].each do |file, signature|
        it "#{spec.gem_dir}#{file} matches checksum" do
          expect(md5("#{spec.gem_dir}#{file}")).to eq(signature)
        end
      end
    end

    private

    def md5(file)
      Digest::MD5.hexdigest(File.read(file))
    end
  end
end
