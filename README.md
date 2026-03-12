# GOV.UK National Applicability Experiment

Feasibility of using machine classification to determine national applicability of GOV.UK content.

## Setup

* Install the version of Ruby specified in `.ruby-version`, e.g. `mise install ruby` (with `idiomatic_version_file_enable_tools` enabled for Ruby).
* Install Ruby libraries by running `bundle install`.
* Install the version of Python specified in `.python-version`, e.g. `mise install python` (with `idiomatic_version_file_enable_tools` enabled for Python).
* Install `pipenv` by running `pip install --user pipenv`.
* Install Python libraries by running `pipenv install`.
* Install the OpenRouter plugin for `llm` by running `pipenv run llm install llm-openrouter`.
* Set the OpenRouter API key by running `pipenv run llm keys set openrouter --value $OPEN_ROUTER_API_KEY`.

## Significant Whitehall commits & pull requests

Some significant changes to the data model and validations for national applicability:
* [Invert the data model regarding which policies apply to which nations](https://github.com/alphagov/whitehall/commit/6573f85076170638940cca5266281fc97ec86d29)
* [Allow exclusion of england](https://github.com/alphagov/whitehall/pull/3766) [Feb 2018]
* [Ensure editions have accurate UK Nation applicability](https://github.com/alphagov/whitehall/pull/5766) [Aug 2020]
* [Set all_nation_applicability for withdrawn editions](https://github.com/alphagov/whitehall/pull/5790) [Sep 2020]
