namespace :export do
  # Helper method to check if required tables exist
  def check_required_tables
    required_tables = ['mammoth_communities', 'mammoth_community_hashtags']
    connection = ActiveRecord::Base.connection
    
    missing_tables = []
    required_tables.each do |table|
      unless connection.table_exists?(table)
        missing_tables << table
      end
    end
    
    if missing_tables.any?
      puts "Error: Required tables are missing: #{missing_tables.join(', ')}"
      puts "Please ensure these tables exist before running the export."
      exit(1)
    end
    
    puts "✓ All required tables exist: #{required_tables.join(', ')}"
  end

  desc "Export community hashtags to CSV file"
  task community_hashtags: :environment do
    require 'csv'
    
    # Check if required tables exist before proceeding
    check_required_tables
    
    output_file = 'community_hashtags.csv'
    puts "Starting export of community hashtags to #{output_file}..."
    
    # SQL query to get community hashtags with is_incoming = true
    sql_query = <<~SQL
      SELECT 
          mc.slug as slug,
          STRING_AGG(mch.hashtag, ', ' ORDER BY mch.hashtag) as hashtag,
          STRING_AGG(mch.name, ', ' ORDER BY mch.name) as name
      FROM mammoth_communities mc
      INNER JOIN mammoth_community_hashtags mch ON mc.id = mch.community_id
      WHERE mch.is_incoming = true
      GROUP BY mc.id, mc.slug
      ORDER BY mc.slug;
    SQL

    begin
      # Execute query using Active Record
      results = ActiveRecord::Base.connection.execute(sql_query)
      
      # Generate CSV file
      CSV.open(output_file, 'w', write_headers: true, headers: ['slug', 'hashtag', 'name']) do |csv|
        results.each do |row|
          csv << [row['slug'], row['hashtag'], row['name']]
        end
      end
      
      puts "Successfully exported #{results.count} records to #{output_file}"
      puts "\nSample data:"
      puts "slug, hashtag, name"
      
      # Show first 5 rows as sample
      results.first(5).each do |row|
        puts "#{row['slug']}, \"#{row['hashtag']}\", \"#{row['name']}\""
      end
      
      puts "\nFile saved to: #{File.absolute_path(output_file)}"
      
    rescue => e
      puts "Error occurred during export: #{e.message}"
      puts e.backtrace
    end
  end

  desc "Export individual community hashtags to CSV file (one row per hashtag)"
  task community_hashtags_individual: :environment do
    require 'csv'
    
    # Check if required tables exist before proceeding
    check_required_tables
    
    output_file = 'community_hashtags_individual.csv'
    puts "Starting export of individual community hashtags to #{output_file}..."
    
    # SQL query for individual rows
    sql_query = <<~SQL
      SELECT 
          mc.slug as slug,
          mch.hashtag as hashtag,
          mch.name as name
      FROM mammoth_communities mc
      INNER JOIN mammoth_community_hashtags mch ON mc.id = mch.community_id
      WHERE mch.is_incoming = true
      ORDER BY mc.slug, mch.hashtag;
    SQL

    begin
      results = ActiveRecord::Base.connection.execute(sql_query)
      
      CSV.open(output_file, 'w', write_headers: true, headers: ['slug', 'hashtag', 'name']) do |csv|
        results.each do |row|
          csv << [row['slug'], row['hashtag'], row['name']]
        end
      end
      
      puts "Successfully exported #{results.count} individual records to #{output_file}"
      puts "File saved to: #{File.absolute_path(output_file)}"
      
    rescue => e
      puts "Error occurred during individual export: #{e.message}"
      puts e.backtrace
    end
  end
end
