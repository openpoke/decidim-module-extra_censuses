# Registering a voting method

This gem adds a voting-method registry on top of `decidim-elections`. A voting
method is an alternative way to vote on a `multiple_option` question and to
compute its results (Borda is the first one). Plain approval voting is the
upstream default and is **not** registered.

Adding a new method means: one register block, one folder of classes, one
folder of cells. No shared view, command, or helper needs to be edited — the
generic code dispatches through the manifest and through a cell naming
convention.

## 1. The register block

Register the method in `lib/decidim/extra_censuses/engine.rb`, next to the
Borda block:

```ruby
Decidim::ExtraCensuses.voting_method_registry.register(:borda) do |manifest|
  manifest.model_concern = "Decidim::ExtraCensuses::VotingMethods::Borda::QuestionFields"
  manifest.form_fields = "Decidim::ExtraCensuses::VotingMethods::Borda::QuestionFormFields"
  manifest.question_validator = "Decidim::ExtraCensuses::VotingMethods::Borda::QuestionValidator"
  manifest.responses_parser = "Decidim::ExtraCensuses::VotingMethods::Borda::ResponsesParser"
  manifest.results_calculator = "Decidim::ExtraCensuses::VotingMethods::Borda::Scorer"
  manifest.config_chips = "Decidim::ExtraCensuses::VotingMethods::Borda::ConfigChipsPresenter"
end
```

Every slot except `name` is optional: leave a slot empty and the generic code
falls back to the upstream behaviour at that seam.

| Slot | Plugged in where | When empty |
|------|------------------|------------|
| `model_concern` | included into `Decidim::Elections::Question` at boot | question gets no extra methods |
| `form_fields` | included into `Decidim::Elections::Admin::QuestionForm` at boot | admin form unchanged |
| `question_validator` | question/form configuration checks | no method-specific validation |
| `responses_parser` | `CastVotes` — turns the raw vote payload into responses | upstream `safe_responses` |
| `results_calculator` | results table, public results, live-update payload | vote counts only |
| `config_chips` | admin dashboard chips next to the question | no extra chips |

`manifest.computes_results?` (derived from `results_calculator`) is the only
predicate shared views branch on — generic code never mentions a method by
name.

## 2. The classes

Per-method classes live under `…/voting_methods/<method>/` in their layer
(`app/models/concerns`, `app/forms/concerns`, `app/services`,
`app/presenters`). Use the Borda classes as the interface reference; the
parser, for example, must implement `#parse(payload)` returning a
`VotingMethods::ParsedResponses` and `#validate!(parsed)`.

## 3. The cells (view surfaces)

Views resolve by convention, not through the manifest.
`voting_method_cell(question, surface)` looks up
`Decidim::ExtraCensuses::VotingMethods::<Method>::<Surface>Cell` and returns
`nil` when the class does not exist, in which case the calling view renders
the upstream markup.

Surfaces currently called from the shared views:

| Surface | Rendered on |
|---------|-------------|
| `response_options` | the voting page (the question's option list) |
| `confirm` | the vote confirmation summary |
| `results` | the public results page |

So a method ships `app/cells/decidim/extra_censuses/voting_methods/<method>/`
with a cell class + views per surface it customises, and simply omits the
surfaces where the upstream rendering is fine.

Inside its cells a method is free to add as many of its own views as it needs
(the Borda results cell has `show`/`options`/`winners`) — nothing there is
registered anywhere. The surface list itself, however, is fixed by the call
sites above: a new surface is added by placing one
`voting_method_cell(question, "<new_surface>")` call in the relevant shared
view or Deface override, which makes it available to every method at once.

## 4. Frontend

If the method needs JavaScript, add a Stimulus controller under
`app/packs/src/decidim/extra_censuses/controllers/` and register it in
`app/packs/src/decidim/extra_censuses/index.js`. Mount it from the method's
own cell markup (`data-controller` plus its `*-value` attributes on a wrapper
the cell renders — see the borda `response_options/show.erb`). Voting-booth
pages only load the `decidim_elections` pack, so the pack-tag Deface override
must list the method's pages too (see the existing `votes/show/add_pack_tag`
override).

## 5. Checklist

1. Classes under `…/voting_methods/<method>/` for the slots you need.
2. Cells under `app/cells/…/voting_methods/<method>/` for the surfaces you customise.
3. Register block in `engine.rb`.
4. Stimulus controller + pack tag, if the method needs JS.
5. i18n keys under `decidim.extra_censuses.…` in `config/locales/`.
