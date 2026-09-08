# Decidim::ExtraCensuses

A new census type "Custom CSV" for Decidim Elections.

## Usage

This module adds a new census type to Decidim Elections that allows administrators to upload custom CSV files with flexible column structures.

## Requirements

This module requires Decidim `~> 0.32.0` and Ruby 3.4. The `max_choices` and census-check-before-start features for election questions that this module extends are included in the official Decidim 0.32 gems, so no fork is needed.

## Installation

Add these lines to your application's Gemfile:

```ruby
gem "decidim", "~> 0.32.0"
gem "decidim-extra_censuses", git: "https://github.com/pokecode/decidim-module-extra_censuses"
```

And then execute:

```bash
bundle install
bundle exec rails decidim_extra_censuses:install:migrations
bundle exec rails db:migrate
```

## Contributing

Contributions are welcome !

We expect the contributions to follow the [Decidim's contribution guide](https://github.com/decidim/decidim/blob/develop/CONTRIBUTING.adoc).

## Security

Security is very important to us. If you have any issue regarding security, please disclose the information responsibly by sending an email to __ivan [at] pokecode [dot] net__ and not by creating a GitHub issue.

## License

This engine is distributed under the GNU AFFERO GENERAL PUBLIC LICENSE.
