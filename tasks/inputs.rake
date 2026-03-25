MODES.each do |mode|
  input_files = []

  content_item_ids(mode).each do |id|
    input_filename = INPUT_DIR.join("#{mode}/#{id}.json")

    file input_filename => [INPUT_DIR.join(mode), NATIONAl_APPLICABILITY_CSV] do |f|
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

  desc "Generate all #{mode} input files"
  task "inputs:#{mode}" => input_files
end
