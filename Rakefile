require 'json'
require 'rake/clean'
require 'csv'
require 'nokogiri'
require 'open3'
require 'tempfile'

SEED = 0.5
MODES = ['training', 'validation']
NATIONS = ['england', 'scotland']

ROOT_DIR = Pathname.new('.')

DATA_DIR = ROOT_DIR.join('data')
INPUT_DIR = ROOT_DIR.join('input')
OUTPUT_DIR = ROOT_DIR.join('output')

NATIONAl_APPLICABILITY_CSV = DATA_DIR.join('national_applicability.csv')
TRAINING_IDS_TXT = DATA_DIR.join('training_ids.txt')
VALIDATION_IDS_TXT = DATA_DIR.join('validation_ids.txt')

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
  directory INPUT_DIR.join(mode)
  NATIONS.each do |nation|
    directory OUTPUT_DIR.join("#{mode}/#{nation}")
  end
end
directory DATA_DIR

desc "Generate #{NATIONAl_APPLICABILITY_CSV} by extracting data from content store database"
file NATIONAl_APPLICABILITY_CSV => DATA_DIR do |f|
  query_file = ROOT_DIR.join('query.sql')
  output = f.name

  sh "govuk-docker up -d content-store-lite"
  sh "docker exec -i govuk-docker-content-store-lite-1 rails db < #{query_file} > #{output}"
  sh "govuk-docker down content-store-lite"
end

desc "Generate #{TRAINING_IDS_TXT} by randomly selecting 250 IDs from #{NATIONAl_APPLICABILITY_CSV}"
file TRAINING_IDS_TXT => [NATIONAl_APPLICABILITY_CSV] do |f|
  training_ids = raw_data['id'].sample(250, random: Random.new(SEED))

  File.open(f.name, 'w') do |file|
    training_ids.each do |id|
      file.puts(id)
    end
  end
end

desc "Generate #{VALIDATION_IDS_TXT} by selecting the other 250 IDs from #{NATIONAl_APPLICABILITY_CSV} not in #{TRAINING_IDS_TXT}"
file VALIDATION_IDS_TXT => [NATIONAl_APPLICABILITY_CSV, TRAINING_IDS_TXT] do |f|
  validation_ids = raw_data['id'] - content_item_ids

  File.open(f.name, 'w') do |file|
    validation_ids.each do |id|
      file.puts(id)
    end
  end
end

desc 'Create input files used to dynamically generate all other tasks'
task :setup => [TRAINING_IDS_TXT, VALIDATION_IDS_TXT]

if File.exist?(TRAINING_IDS_TXT) && File.exist?(VALIDATION_IDS_TXT)
  load 'tasks/inputs.rake'
  load 'tasks/outputs.rake'

  desc 'Generate all files in input/'
  task :inputs => MODES.map { |mode| "inputs:#{mode}" }

  desc 'Generate results for each nation for each mode'
  task :results => MODES.flat_map { |mode| NATIONS.map { |nation| OUTPUT_DIR.join("#{mode}/#{nation}/results.txt") } }

  desc 'Generate summaries for each nation for each mode'
  task :summaries => MODES.flat_map { |mode| NATIONS.map { |nation| OUTPUT_DIR.join("#{mode}/#{nation}/summary.txt") } }

  task :default => :summaries
else
  task :default => :setup
end

CLOBBER.include(OUTPUT_DIR, INPUT_DIR, DATA_DIR)
