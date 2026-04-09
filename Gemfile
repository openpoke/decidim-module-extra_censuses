# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = ""
base_path = "../" if File.basename(__dir__) == "development_app"
require_relative "#{base_path}lib/decidim/extra_censuses/version"

DECIDIM_VERSION = Decidim::ExtraCensuses::DECIDIM_VERSION

gem "decidim", git: "https://github.com/openpoke/decidim", branch: "0.31-backports"
gem "decidim-elections", git: "https://github.com/openpoke/decidim", branch: "0.31-backports"
gem "decidim-extra_censuses", path: "."

gem "bootsnap", "~> 1.7"
gem "puma", ">= 6.3.1"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", git: "https://github.com/openpoke/decidim", branch: "0.31-backports"
  gem "decidim-initiatives", git: "https://github.com/openpoke/decidim", branch: "0.31-backports"

  gem "brakeman", "~> 6.1"
end

group :development do
  gem "letter_opener_web"
  gem "listen", "~> 3.1"
  gem "web-console"
end
