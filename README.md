# Decidim::ExtraCensuses

A new census type "Custom CSV" for Decidim Elections.

## Usage

This module adds a new census type to Decidim Elections that allows administrators to upload custom CSV files with flexible column structures.

## Requirements

This module requires the [openpoke/decidim](https://github.com/openpoke/decidim) fork, branch `0.31-backports`. The official Decidim 0.31 gem does not include the `max_choices` feature for elections questions that this module extends.

## Installation

Add these lines to your application's Gemfile:

```ruby
gem "decidim", git: "https://github.com/openpoke/decidim", branch: "0.31-backports"
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
