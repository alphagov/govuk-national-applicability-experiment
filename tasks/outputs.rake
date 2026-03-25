MODES.each do |mode|
  NATIONS.each do |nation|
    output_files = []

    content_item_ids(mode).each do |id|
      output_file = OUTPUT_DIR.join("#{mode}/#{nation}/#{id}.json")

      file output_file => [OUTPUT_DIR.join("#{mode}/#{nation}"), INPUT_DIR.join("#{mode}/#{id}.json")] do |f|
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

      output_files << output_file
    end

    desc "Generate all #{mode} output files for #{nation}"
    task "outputs:#{mode}:#{nation}" => output_files

    file OUTPUT_DIR.join("#{mode}/#{nation}/results.csv") => "outputs:#{mode}:#{nation}" do |f|
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
