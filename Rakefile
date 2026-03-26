require 'json'
require 'rake/clean'
require 'csv'

SEED = 0.5
MODES = ['training', 'validation']
NATIONS = ['england', 'scotland']

ROOT_DIR = Pathname.new('.')

DATA_DIR = ROOT_DIR.join('data')
INPUT_DIR = ROOT_DIR.join('input')
OUTPUT_DIR = ROOT_DIR.join('output')

NATIONAL_APPLICABILITY_CSV = DATA_DIR.join('national_applicability.csv')
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
  @data ||= CSV.read(NATIONAL_APPLICABILITY_CSV, headers: true)
end

load 'tasks/setup.rake'

if File.exist?(TRAINING_IDS_TXT) && File.exist?(VALIDATION_IDS_TXT)
  load 'tasks/inputs.rake'
  load 'tasks/outputs.rake'

  task :default => :summaries
else
  task :default => :setup
end

CLOBBER.include(OUTPUT_DIR, INPUT_DIR, DATA_DIR)
