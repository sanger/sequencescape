namespace :db do
  namespace :views do
    desc 'Export the views to a schema file'
    task :dump_schema => :environment do
      File.open('./db/views_schema.rb','w') do |schema|
        schema.puts "# This is an automatically generated file by rake:db:views:dump_schema"
        ViewsSchema.each_view do |name,definition|
          schema.puts "ViewsSchema.create_view("
          schema.puts "'#{name}',"
          schema.puts "%Q{#{definition}}"
          schema.puts ')'
        end
      end
    end

    desc 'Reload the dumped schema'
    task :schema_load => :environment  do
      require './db/views_schema'
    end

  end
end
