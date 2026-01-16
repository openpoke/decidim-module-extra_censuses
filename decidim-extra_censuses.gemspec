# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/extra_censuses/version"

Gem::Specification.new do |s|
  s.version = Decidim::ExtraCensuses::VERSION
  s.authors = ["Ivan Vergés"]
  s.email = ["ivan@pokecode.net"]
  s.license = "AGPL-3.0-or-later"
  s.homepage = "https://decidim.org"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/openpoke/decidim-module-extra_censuses/issues",
    "source_code_uri" => "https://github.com/openpoke/decidim-module-extra_censuses"
  }
  s.required_ruby_version = "~> 3.3"

  s.name = "decidim-extra_censuses"
  s.summary = "Extra Censuses For the Election Component"
  s.description = "Extra Censuses For the Election Component."

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").select do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w(app/ config/ db/ lib/ LICENSE-AGPLv3.txt Rakefile README.md))
    end
  end

  s.add_dependency "decidim-core", Decidim::ExtraCensuses::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-elections", Decidim::ExtraCensuses::COMPAT_DECIDIM_VERSION
end
