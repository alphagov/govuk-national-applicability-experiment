require 'json'
require 'rake/clean'
require 'csv'

SEED = 0.5

directory 'input'
directory 'output'
directory 'data'

desc 'Randomly select 100 content ids to use as training data'
file 'data/training_ids.txt' => ['data', 'data/national_applicability.csv'] do |f|
  sample = raw_data.to_a[1..].sample(100, random: Random.new(SEED))

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

training_ids.each do |id|
  desc "Prepare input file #{id}.json"
  file "input/#{id}.json" => ['input', 'data/national_applicability.csv'] do |f|
    puts "Creating #{f.name}"
    data = raw_data.find {|r| r['id'] == id}

    File.write(f.name, {
                 body: data['body'],
                 applies_to_england: to_boolean(data['applies_to_england'])
               }.to_json)
  end
end

# Could have a loop over prompts, models etc here
training_ids.each do |id|
  desc "Prepare output file #{id}.json"
  file "output/#{id}.json" => ['output', "input/#{id}.json"] do |f|
    puts "Creating #{f.name}"
    File.write(f.name, { body: "Body for #{id}" }.to_json)
  end
end

file 'results.csv' => training_ids.map { |id| "output/#{id}.json" } do |f|
  puts "Creating #{f.name}"

  CSV.open(f.name, 'w') do |csv|
    csv << ['id', 'body']  # header row

    Dir.glob('output/*.json') do |f|
      data = JSON.parse(File.read(f))
      id = File.basename(f, '.json')
      csv << [id, data['body']]
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

task :default do
  Rake::Task['setup'].invoke
  exec('rake', 'results.csv')
end

CLOBBER.include('output', 'input', 'data', 'results.csv')
