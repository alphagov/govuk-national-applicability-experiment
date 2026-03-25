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

load 'tasks/setup.rake'

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
