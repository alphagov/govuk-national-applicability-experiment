# GOV.UK National Applicability Experiment

Feasibility of using machine classification to determine national applicability of GOV.UK content.

This repo contains code used to explore the idea of using an off-the-shelf Large Language Model (LLM) to determine the national applicability of content published on GOV.UK.

## Experiment overview

To constrain the experiment we treated it as a binary classification problem (i.e. "does this document apply to <nation>?") and to restrict it to only England and Scotland.

We used [GPT-4o mini](https://developers.openai.com/api/docs/models/gpt-4o-mini) (knowledge cutoff of 1 Oct 2023) to perform the classification.

We used a training set of 250 documents published after 1 Jan 2024 to iterate on the data cleansing, context and LLM prompt to improve classification performance.

We validated the experiment against a held-out set of 250 documents.

### Results

#### [Results for documents that apply to England](./output/validation/england/summary.txt)

- true_positive: 241
- true_negative: 9
- false_positive: 0
- false_negative: 0
- correct: 250
- incorrect: 0

#### [Results for documents that apply to Scotland](./output/validation/scotland/summary.txt)

- true_positive: 12
- true_negative: 218
- false_positive: 10
- false_negative: 10
- correct: 230
- incorrect: 20

### Discussion

The results from this experiment show that it is possible to accurately predict the national applicability of documents in the "England" case, and achieve reasonable results in the "Scotland" case. This shows that the text classifier using an LLM approach has some promise for this kind of task.

It's important to note that we only have national applicability metadata in the data sets when a publisher has *explicitly* chosen that the document does not apply to a particular nation. Choosing the "applies to all nations" option in Whitehall means that no national applicability metadata is added to the document. Publishers have to choose one option so this serves as the de facto default choice. A brief look at the results when we included these "applies to all nations" document indicated much worse performance.

This experiment showed us that ideally we'd use clean training data that had been labelled for the purpose of training a classifier. Using "found" data, as we did here, is less reliable.

## Experiment artefacts in this repo

For each of the 250 training and 250 validation documents we generate an "input" JSON document containing:

- document title
- document body
- whether a publisher has explicitly indicated that it applies to England
- whether a published has explicitly indicated that it applies to Scotland

These files (1 per document named as the document ID) are stored in the `./input/(training|validation)/` folders.

For each of the 250 training and 250 validation documents, and for each of England and Scotland, we generate an "output" JSON document containing:

- the LLM prompt used
- the LLM's verdict as to whether the document applies to the nation
- the LLM's reason for its national applicability answer

These files (1 per document named as the document ID) are stored in the `./output/(training|validation)/(england|scotland)/` folders.

For each of training and validation, and for each of England and Scotland, we generate a results.csv which records:

- the document ID
- whether it applies to the nation according to the publisher
- whether it applies to the nation according to the llm
- the LLM's reason.

These are stored in `./output/(training|validation)/(england|scotland)/results.csv`.

For each of training and validation, and for each of England and Scotland, we generate a summary.txt which records:

- number of true positives
- number of true negatives
- number of false positives
- number of false negatives
- number of true positives + true negatives (i.e. where the llm matched the publisher)
- number of false positives + false negatives (i.e. where the llm didn't match the publisher)
- list of document IDs where the llm didn't match the publisher

These are stored in `./output/(training|validation)/(england|scotland)/summary.txt`.

The data in these summary.txt files can be used to generate a [Confusion matrix](https://en.wikipedia.org/wiki/Confusion_matrix) to illustrate how well the algorithm performed.

### Directory structure of artefacts

```
data/
|- national_applicability.csv
|- training_ids.txt
|- validation_ids.txt
input/
|- training/
|  |- *.json
|- validation/
|  |- *.json
output/
|- training/
|  |- england/
|  |  |- *.json
|  |  |- results.csv
|  |  |- summary.csv
|  |- scotland/
|  |  |- *.json
|  |  |- results.csv
|  |  |- summary.csv
|- validation/
|  |- england/
|  |  |- *.json
|  |  |- results.csv
|  |  |- summary.csv
|  |- scotland/
|  |  |- *.json
|  |  |- results.csv
|  |  |- summary.csv
```

## Re-running the experiment

We use Rake to create a pipeline of files tasks that lead to the eventual creation of the summary.csv files.

To re-run the experiment you'll first need:

- [govuk-docker](https://github.com/alphagov/govuk-docker/)
- [content-store](https://github.com/alphagov/content-store)
- [dump of content-store database](https://github.com/alphagov/govuk-docker/blob/main/docs/how-tos.md#how-to-replicate-data-locally)
- [OpenRouter](https://openrouter.ai/) API Key

Then install and configure the dependencies:

- Install the version of Ruby specified in `.ruby-version`, e.g. `mise install ruby` (with `idiomatic_version_file_enable_tools` enabled for Ruby).
- Install Ruby libraries by running `bundle install`.
- Install the version of Python specified in `.python-version`, e.g. `mise install python` (with `idiomatic_version_file_enable_tools` enabled for Python).
- Install `pipenv` by running `pip install --user pipenv`.
- Install Python libraries by running `pipenv install`.
- Install the OpenRouter plugin for `llm` by running `pipenv run llm install llm-openrouter`.
- Set the OpenRouter API key by running `pipenv run llm keys set openrouter --value $OPEN_ROUTER_API_KEY`.

Finally re-run the experiment:

- Run `rake clobber` to clear all the artefacts that are stored in this repo
- Run `rake` to generate the source files that are used to dynamically define all other Rake tasks
- Run `rake --multitask` to process the complete pipeline and generate all other files (this takes approx 25 mins on a CPU with 6 cores)

Note that even without any changes to the set of input documents you're still _very_ likely to see changes in the output documents because of the non-deterministic nature of the LLM.

## Understanding the Rake tasks

1. `data/national_applicability.csv` - extracts 500 rows from the `content_items` table in the content store database (see query.sql)
2. `data/training_ids.txt` - takes 250 IDs at random from `data/national_applicability.csv`
3. `data/validation_ids.txt` - takes the remaining 250 IDs from `data/national_applicability.csv` that aren't in `data/training_ids.txt`.
6. `inputs` - Generate an input file for each of the 500 documents in the export
7. `output` - Generate an output file each of the 500 documents in the export for each of the 2 nations
8. `results` - Generate a results.csv file for each of training|validation and each of england|scotland
9. `summaries` - Generate a summary.txt file for each of training|validation and each of england|scotland

## Limitations of the experiment

We're only selecting documents where a publisher has explicitly indicated that they apply to a subset of the 4 nations of the UK. Which means we've tested this approach against any documents that apply to the whole of the UK.

## Significant Whitehall commits & pull requests

Some significant changes to the data model and validations for national applicability:
* [Invert the data model regarding which policies apply to which nations](https://github.com/alphagov/whitehall/commit/6573f85076170638940cca5266281fc97ec86d29)
* [Allow exclusion of england](https://github.com/alphagov/whitehall/pull/3766) [Feb 2018]
* [Ensure editions have accurate UK Nation applicability](https://github.com/alphagov/whitehall/pull/5766) [Aug 2020]
* [Set all_nation_applicability for withdrawn editions](https://github.com/alphagov/whitehall/pull/5790) [Sep 2020]
