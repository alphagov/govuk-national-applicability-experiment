require 'json'
require 'rake/clean'
require 'csv'
require 'nokogiri'
require 'open3'
require 'tempfile'

SEED = 0.5
MODES = ['training', 'validation']
NATIONS = ['england', 'scotland']

INPUT_DIR = Pathname.new('input')

MODES.each do |mode|
  directory INPUT_DIR.join(mode)
  NATIONS.each do |nation|
    directory "output/#{mode}/#{nation}"
  end
end
directory 'data'

desc 'Randomly select 250 content ids to use as training data'
file 'data/training_ids.txt' => ['data', 'data/national_applicability.csv'] do |f|
  training_ids = raw_data['id'].sample(250, random: Random.new(SEED))

  File.open('data/training_ids.txt', 'w') do |file|
    training_ids.each do |id|
      file.puts(id)
    end
  end
end

desc 'Randomly select 250 content ids to use as validation data'
file 'data/validation_ids.txt' => ['data', 'data/national_applicability.csv', 'data/training_ids.txt'] do |f|
  validation_ids = raw_data['id'] - content_item_ids

  File.open('data/validation_ids.txt', 'w') do |file|
    validation_ids.each do |id|
      file.puts(id)
    end
  end
end

def content_item_ids(mode = 'training')
  if File.exist?("data/#{mode}_ids.txt")
    File.readlines("data/#{mode}_ids.txt", chomp: true)
  else
    []
  end
end

def raw_data
  @data ||= CSV.read('data/national_applicability.csv', headers: true)
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
    file INPUT_DIR.join("#{mode}/#{id}.json") => [INPUT_DIR.join(mode), 'data/national_applicability.csv'] do |f|
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
      file "output/#{mode}/#{nation}/#{id}.json" => ["output/#{mode}/#{nation}", INPUT_DIR.join("#{mode}/#{id}.json")] do |f|
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
    file "output/#{mode}/#{nation}/results.csv" => content_item_ids(mode).map { |id| "output/#{mode}/#{nation}/#{id}.json" } do |f|
      puts "Creating #{f.name}"

      CSV.open(f.name, 'w') do |csv|
        csv << ['id', 'applies_to_nation_input', 'applies_to_nation_output', 'reason']

        content_item_ids(mode).each do |id|
          input_fn = INPUT_DIR.join("#{mode}/#{id}.json")
          output_fn = "output/#{mode}/#{nation}/#{id}.json"
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
    file "output/#{mode}/#{nation}/summary.txt" => "output/#{mode}/#{nation}/results.csv" do |f|
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
file 'data/national_applicability.csv' => 'data' do
  query_file = File.join(File.dirname(__FILE__), 'query.sql')
  output = File.join(File.dirname(__FILE__), 'data', 'national_applicability.csv')

  sh "govuk-docker up -d content-store-lite"
  sh "docker exec -i govuk-docker-content-store-lite-1 rails db < #{query_file} > #{output}"
  sh "govuk-docker down content-store-lite"
end

desc 'Create input files used to dynamically generate all other tasks'
task :setup => ['data/training_ids.txt', 'data/validation_ids.txt']

task :summaries => MODES.flat_map { |mode| NATIONS.map { |nation| "output/#{mode}/#{nation}/summary.txt" } }

if File.exist?('data/training_ids.txt') && File.exist?('data/validation_ids.txt')
  task :default => :summaries
else
  task :default => :setup
end

CLOBBER.include('output', INPUT_DIR, 'data')
