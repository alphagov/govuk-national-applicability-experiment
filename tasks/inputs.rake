require 'nokogiri'

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
  input_files = []

  content_item_ids(mode).each do |id|
    input_filename = INPUT_DIR.join("#{mode}/#{id}.json")

    file input_filename => [INPUT_DIR.join(mode), NATIONAL_APPLICABILITY_CSV] do |f|
      puts "Creating #{f.name}"
      data = raw_data.find {|r| r['id'] == id}

      File.write(f.name, JSON.pretty_generate({
                  title: data['title'],
                  body: strip_tags(data['body']),
                  applies_to_england: to_boolean(data['applies_to_england']),
                  applies_to_scotland: to_boolean(data['applies_to_scotland'])
                }))
    end

    input_files << input_filename
  end

  desc "Create all #{INPUT_DIR.join(mode).join('*.json')} files"
  task "inputs:#{mode}" => input_files
end

desc "Create all #{INPUT_DIR.join('**').join('*.json')} files"
task :inputs => MODES.map { |mode| "inputs:#{mode}" }
