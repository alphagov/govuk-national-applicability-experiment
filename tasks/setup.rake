MODES.each do |mode|
  directory INPUT_DIR.join(mode)
  NATIONS.each do |nation|
    directory OUTPUT_DIR.join("#{mode}/#{nation}")
  end
end
directory DATA_DIR

desc "Create #{NATIONAl_APPLICABILITY_CSV} by extracting required data from the content_items table in the content store database"
file NATIONAl_APPLICABILITY_CSV => DATA_DIR do |f|
  query_file = ROOT_DIR.join('query.sql')
  output = f.name

  sh "govuk-docker up -d content-store-lite"
  sh "docker exec -i govuk-docker-content-store-lite-1 rails db < #{query_file} > #{output}"
  sh "govuk-docker down content-store-lite"
end

desc "Create #{TRAINING_IDS_TXT} by randomly selecting 250 IDs from #{NATIONAl_APPLICABILITY_CSV}"
file TRAINING_IDS_TXT => [NATIONAl_APPLICABILITY_CSV] do |f|
  training_ids = raw_data['id'].sample(250, random: Random.new(SEED))

  File.open(f.name, 'w') do |file|
    training_ids.each do |id|
      file.puts(id)
    end
  end
end

desc "Create #{VALIDATION_IDS_TXT} by selecting the other 250 IDs from #{NATIONAl_APPLICABILITY_CSV} not in #{TRAINING_IDS_TXT}"
file VALIDATION_IDS_TXT => [NATIONAl_APPLICABILITY_CSV, TRAINING_IDS_TXT] do |f|
  validation_ids = raw_data['id'] - content_item_ids

  File.open(f.name, 'w') do |file|
    validation_ids.each do |id|
      file.puts(id)
    end
  end
end

desc "Create all #{DATA_DIR.join('*')} files used to dynamically generate all other tasks"
task :setup => [TRAINING_IDS_TXT, VALIDATION_IDS_TXT]
