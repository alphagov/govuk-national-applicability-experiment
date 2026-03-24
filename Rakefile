require 'json'
require 'rake/clean'
require 'csv'
require 'nokogiri'
require 'open3'
require 'tempfile'

SEED = 0.5
MODES = ['training', 'validation']
NATIONS = ['england', 'scotland']

DATA_DIR = Pathname.new('data')
INPUT_DIR = Pathname.new('input')
OUTPUT_DIR = Pathname.new('output')

NATIONAl_APPLICABILITY_CSV = DATA_DIR.join('national_applicability.csv')
TRAINING_IDS_TXT = DATA_DIR.join('training_ids.txt')
VALIDATION_IDS_TXT = DATA_DIR.join('validation_ids.txt')

MODES.each do |mode|
  directory INPUT_DIR.join(mode)
  NATIONS.each do |nation|
    directory OUTPUT_DIR.join("#{mode}/#{nation}")
  end
end
directory DATA_DIR

desc 'Randomly select 250 content ids to use as training data'
file TRAINING_IDS_TXT => [NATIONAl_APPLICABILITY_CSV] do |f|
  training_ids = raw_data['id'].sample(250, random: Random.new(SEED))

  File.open(TRAINING_IDS_TXT, 'w') do |file|
    training_ids.each do |id|
      file.puts(id)
    end
  end
end

desc 'Randomly select 250 content ids to use as validation data'
file VALIDATION_IDS_TXT => [NATIONAl_APPLICABILITY_CSV, TRAINING_IDS_TXT] do |f|
  validation_ids = raw_data['id'] - content_item_ids

  File.open(VALIDATION_IDS_TXT, 'w') do |file|
    validation_ids.each do |id|
      file.puts(id)
    end
  end
end

def content_item_ids(mode = 'training')
  if File.exist?(DATA_DIR.join("#{mode}_ids.txt"))
    File.readlines(DATA_DIR.join("#{mode}_ids.txt"), chomp: true)
  else
    []
  end
end

def raw_data
  @data ||= CSV.read(NATIONAl_APPLICABILITY_CSV, headers: true)
end

def to_boolean(s)
  case s.downcase
  when "t" then true
  when "f" then false
  end
end

def strip_tags(s)
  Nokogiri.HTML(s).text.gsub(/\\n\s*/, " ")
end

MODES.each do |mode|
  content_item_ids(mode).each do |id|
    desc "Prepare #{mode} input file #{id}.json"
    file INPUT_DIR.join("#{mode}/#{id}.json") => [INPUT_DIR.join(mode), NATIONAl_APPLICABILITY_CSV] do |f|
      puts "Creating #{f.name}"
      data = raw_data.find {|r| r['id'] == id}

      File.write(f.name, JSON.pretty_generate({
                  title: data['title'],
                  body: strip_tags(data['body']),
                  applies_to_england: to_boolean(data['applies_to_england']),
                  applies_to_scotland: to_boolean(data['applies_to_scotland'])
                }))
    end
  end
end

desc 'Regenerate all files in input/'
task :inputs => MODES.flat_map { |mode| content_item_ids(mode).map { |id| INPUT_DIR.join("#{mode}/#{id}.json") } }

MODES.each do |mode|
  NATIONS.each do |nation|
    content_item_ids(mode).each do |id|
      desc "Prepare #{mode} output file #{id}.json"
      file OUTPUT_DIR.join("#{mode}/#{nation}/#{id}.json") => [OUTPUT_DIR.join("#{mode}/#{nation}"), INPUT_DIR.join("#{mode}/#{id}.json")] do |f|
        input = JSON.load_file(INPUT_DIR.join("#{mode}/#{id}.json"))
        input_text = [input['title'], input['body']].join("\n\n")

        prompt = "This document is to be published on the UK GOV.UK government website. It may apply to one or more of the nations of the UK (England, Wales, Scotland or Northern Ireland). State whether it applies to #{nation} and give a short explanation (less than 100 words) for your decision."

        output = {
          prompt:,
        }

        if ENV['SKIP_LLM'] == 'true'
          stdout = '{}'
        else
          stdout, stderr, status = Open3.capture3(
            'pipenv', 'run', 'llm',
            '-m', 'openrouter/openai/gpt-4o-mini',
            '--schema', 'applies_to_nation bool, reason',
            '--system', prompt,
            stdin_data: input_text
          )
        end

        output_json = JSON.parse(stdout)
        output.merge!(output_json)

        puts "Creating #{f.name}"
        File.write(f.name, JSON.pretty_generate(output))
      end
    end
  end
end

MODES.each do |mode|
  NATIONS.each do |nation|
    file OUTPUT_DIR.join("#{mode}/#{nation}/results.csv") => content_item_ids(mode).map { |id| OUTPUT_DIR.join("#{mode}/#{nation}/#{id}.json") } do |f|
      puts "Creating #{f.name}"

      CSV.open(f.name, 'w') do |csv|
        csv << ['id', 'applies_to_nation_input', 'applies_to_nation_output', 'reason']

        content_item_ids(mode).each do |id|
          input_fn = INPUT_DIR.join("#{mode}/#{id}.json")
          output_fn = OUTPUT_DIR.join("#{mode}/#{nation}/#{id}.json")
          input_json = JSON.load_file(input_fn)
          output_json = JSON.load_file(output_fn)

          csv << [id, input_json["applies_to_#{nation}"], output_json['applies_to_nation'], output_json['reason']]
        end
      end
    end
  end
end

MODES.each do |mode|
  NATIONS.each do |nation|
    file OUTPUT_DIR.join("#{mode}/#{nation}/summary.txt") => OUTPUT_DIR.join("#{mode}/#{nation}/results.csv") do |f|
      puts "Creating #{f.name}"
      results = CSV.read(f.prerequisites[0], headers: true)

      true_positive = 0
      true_negative = 0
      false_positive = 0
      false_negative = 0

      incorrect_ids = []

      results.each do |row|
        true_positive += 1 if row['applies_to_nation_input'] == 'true' && row['applies_to_nation_output'] == 'true'
        true_negative += 1 if row['applies_to_nation_input'] == 'false' && row['applies_to_nation_output'] == 'false'
        false_positive += 1 if row['applies_to_nation_input'] == 'false' && row['applies_to_nation_output'] == 'true'
        false_negative += 1 if row['applies_to_nation_input'] == 'true' && row['applies_to_nation_output'] == 'false'

        incorrect_ids << row['id'] if row['applies_to_nation_input'] != row['applies_to_nation_output']
      end

      File.open(f.name, 'w') do |file|
        file.puts "true_positive: #{true_positive}"
        file.puts "true_negative: #{true_negative}"
        file.puts "false_positive: #{false_positive}"
        file.puts "false_negative: #{false_negative}"
        file.puts "correct: #{true_positive + true_negative}"
        file.puts "incorrect: #{false_positive + false_negative}"

        file.puts "Incorrect IDs:"
        file.puts incorrect_ids.join("\n")
      end
    end
  end
end

desc 'Prepare input CSV file by querying content store database'
file NATIONAl_APPLICABILITY_CSV => DATA_DIR do
  query_file = File.join(File.dirname(__FILE__), 'query.sql')
  output = NATIONAl_APPLICABILITY_CSV

  sh "govuk-docker up -d content-store-lite"
  sh "docker exec -i govuk-docker-content-store-lite-1 rails db < #{query_file} > #{output}"
  sh "govuk-docker down content-store-lite"
end

desc 'Create input files used to dynamically generate all other tasks'
task :setup => [TRAINING_IDS_TXT, VALIDATION_IDS_TXT]

task :summaries => MODES.flat_map { |mode| NATIONS.map { |nation| OUTPUT_DIR.join("#{mode}/#{nation}/summary.txt") } }

if File.exist?(TRAINING_IDS_TXT) && File.exist?(VALIDATION_IDS_TXT)
  task :default => :summaries
else
  task :default => :setup
end

CLOBBER.include(OUTPUT_DIR, INPUT_DIR, DATA_DIR)
