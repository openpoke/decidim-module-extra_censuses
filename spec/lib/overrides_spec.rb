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
        # forms
        "/app/forms/decidim/elections/admin/question_form.rb" => "df808ddabd28c135e45b6fe4df0325a7",
        # commands
        "/app/commands/decidim/elections/admin/update_questions.rb" => "2b64fc68a96bbd352becb311a8415eb0",
        # controllers
        "/app/controllers/decidim/elections/admin/census_controller.rb" => "f3a866fe5f69f378cf419a40304b97e0",
        "/app/controllers/decidim/elections/votes_controller.rb" => "53a611d2a456e2032b986a76cdcf6bf1",
        "/app/controllers/decidim/elections/per_question_votes_controller.rb" => "fa6a7d89d010bbe8faa02d3e89c94d43",
        # helpers
        "/app/helpers/decidim/elections/application_helper.rb" => "c299bc5843e4c3c361756b5fdf602237",
        # views
        "/app/views/decidim/elections/admin/questions/_question.html.erb" => "c679c5aa57ed5307845c4ebb2737558d"
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
