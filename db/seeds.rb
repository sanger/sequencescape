# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

##########################################################################################################
# WARNING: Seeding anything other than the development or test DB takes someone who knows exactly what
# they are doing.  So here we're preventing you from actually doing that.
##########################################################################################################
unless [ :development, :test, :seeding ].include?(Rails.env.to_sym)
  raise StandardError, <<-END_OF_MESSAGE
**********************************************************************************************************
********************************** SERIOUSLY, YOU DON'T WANT TO DO THIS ********************************** 

You are quite clearly either wreckless, incompetent or insane.  You are trying to seed the #{ Rails.env }
database which should never be done.  Please recheck your shell environment to ensure that RAILS_ENV
is not set, or is set to either 'development' or 'test'.

**********************************************************************************************************
**********************************************************************************************************
END_OF_MESSAGE
end

# Why this stuff isn't run in a transaction I don't know!
ActiveRecord::Base.transaction do
  # Load all of the files under the 'seeds' directory in their sorted order.  This allows us to define
  # separate files for different sets of seed data and to govern the order they are created in.  For
  # example, property definitions depend on workflows to be present, so they should be ordered *after*
  # those workflows have been created.  Ideally you will be preceeding your seed data with a 4 digit
  # 0-extended sequence number, i.e. 0001_foo.rb is executed *before* 0002_bar.rb.
  Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), %w{seeds *.rb}))).sort.each do |seed_data_file|
    Rails.logger.info("Loading seed data from #{ seed_data_file } ...")
    require seed_data_file
    Rails.logger.info("Seed data loaded from #{ seed_data_file }")
  end
end