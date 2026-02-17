require 'json'
require 'rake/clean'
require 'csv'
require 'nokogiri'
require 'open3'
require 'tempfile'

SEED = 0.5
NATIONS = ['england', 'scotland']

directory 'input'
NATIONS.each do |nation|
  directory "output/#{nation}"
end
directory 'data'

desc 'Randomly select 250 content ids to use as training data'
file 'data/training_ids.txt' => ['data', 'data/national_applicability.csv'] do |f|
  sample = raw_data.to_a[1..].sample(250, random: Random.new(SEED))

  File.open('data/training_ids.txt', 'w') do |file|
    sample.each do |row|
      id = row[0]
      file.puts(id)
    end
  end
end

def training_ids
  if File.exist?('data/training_ids.txt')
    File.readlines('data/training_ids.txt', chomp: true)
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

training_ids.each do |id|
  desc "Prepare input file #{id}.json"
  file "input/#{id}.json" => ['input', 'data/national_applicability.csv'] do |f|
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

desc 'Regenerate all files in input/'
task :inputs => training_ids.map { |id| "input/#{id}.json" }

NATIONS.each do |nation|
  training_ids.each do |id|
    desc "Prepare output file #{id}.json"
    file "output/#{nation}/#{id}.json" => ["output/#{nation}", "input/#{id}.json"] do |f|
      input = JSON.load_file("input/#{id}.json")
      input_text = [input['title'], input['body']].join("\n\n")

      prompt = "This document is to be published on the UK GOV.UK government website. It may apply to one or more of the nations of the UK (England, Wales, Scotland or Northern Ireland). State whether it applies to #{nation} and give a short explanation (less than 100 words) for your decision."

      output = {
        prompt:,
      }

      Tempfile.create do |tempfile|
        tempfile.puts(input_text)
        tempfile.rewind

        stdout, stderr, status = Open3.capture3(
          'pipenv', 'run', 'llm',
          '-m', 'openrouter/openai/gpt-4o-mini',
          '--schema', 'applies_to_nation bool, reason',
          '--system', "'#{prompt}'",
          stdin_data: tempfile.read
        )

        output_json = JSON.parse(stdout)
        output.merge!(output_json)
      end

      puts "Creating #{f.name}"
      File.write(f.name, JSON.pretty_generate(output))
    end
  end
end

NATIONS.each do |nation|
  file "output/#{nation}/results.csv" => training_ids.map { |id| "output/#{nation}/#{id}.json" } do |f|
    puts "Creating #{f.name}"

    CSV.open(f.name, 'w') do |csv|
      csv << ['id', 'applies_to_nation_input', 'applies_to_nation_output', 'reason']

      training_ids.each do |id|
        input_fn = "input/#{id}.json"
        output_fn = "output/#{nation}/#{id}.json"
        input_json = JSON.load_file(input_fn)
        output_json = JSON.load_file(output_fn)

        csv << [id, input_json["applies_to_#{nation}"], output_json['applies_to_nation'], output_json['reason']]
      end
    end
  end
end

NATIONS.each do |nation|
  file "output/#{nation}/summary.txt" => "output/#{nation}/results.csv" do |f|
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

desc 'Prepare input CSV file by querying content store database'
file 'data/national_applicability.csv' => 'data' do
  query_file = File.join(File.dirname(__FILE__), 'query.sql')
  output = File.join(File.dirname(__FILE__), 'data', 'national_applicability.csv')

  system("govuk-docker up -d content-store-lite")
  system("docker exec -i govuk-docker-content-store-lite-1 rails db < #{query_file} > #{output}")
  system("govuk-docker down content-store-lite")
end

task :setup => ['data/training_ids.txt']
task :summaries => NATIONS.map { |nation| "output/#{nation}/summary.txt" }

task :default do
  Rake::Task['setup'].invoke
  exec('rake', 'summaries')
end

CLOBBER.include('output', 'input', 'data')
