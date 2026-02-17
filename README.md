# gds-national-applicability

Feasibility of using machine classification to determine national applicability of GOV.UK content.

## Setup

```
mise install
pip install llm
llm install llm-openrouter
```

The add the OpenRouter API key (in our 1P vault)

```
llm keys set openrouter
```

## Setup (improved)

* Install the version of Ruby specified in `.ruby-version`, e.g. `mise install ruby` (with `idiomatic_version_file_enable_tools` enabled for Ruby).
* Install Ruby libraries by running `bundle install`.
