require 'json'
require 'rake/clean'
require 'csv'

# In the real thing we'd read these from the CSV file/database
DOCUMENT_IDS = [1, 2, 3, 4]

directory 'input'
directory 'output'
directory 'data'

DOCUMENT_IDS.each do |id|
  desc "Prepare input file #{id}.json"
  file "input/#{id}.json" => ['input', 'data/national_applicability.csv'] do |f|
    puts "Creating #{f.name}"
    File.write(f.name, { body: "Body for #{id}" }.to_json)
  end
end

# Could have a loop over prompts, models etc here
DOCUMENT_IDS.each do |id|
  desc "Prepare output file #{id}.json"
  file "output/#{id}.json" => ['output', "input/#{id}.json"] do |f|
    puts "Creating #{f.name}"
    File.write(f.name, { body: "Body for #{id}" }.to_json)
  end
end

file 'results.csv' => DOCUMENT_IDS.map { |id| "output/#{id}.json" } do |f|
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

task default: %w[results.csv]

CLOBBER.include('output', 'input', 'data', 'results.csv')
