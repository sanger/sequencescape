# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

##########################################################################################################
# WARNING: Seeding anything other than the development or test DB takes someone who knows exactly what
# they are doing.  So here we're preventing you from actually doing that.
##########################################################################################################
raise StandardError, <<~END_OF_MESSAGE unless %i[development test seeding cucumber].include?(Rails.env.to_sym)
    **********************************************************************************************************
    ********************************** SERIOUSLY, YOU DON'T WANT TO DO THIS **********************************

    You are quite clearly either wreckless, incompetent or careless.  You are trying to seed the #{Rails.env}
    database which should never be done.  Please recheck your shell environment to ensure that Rails.env
    is not set, or is set to either 'development' or 'test'.

    **********************************************************************************************************
    **********************************************************************************************************
  END_OF_MESSAGE

if Rails.env.test?
  Rails.logger.warn(<<~END_OF_MESSAGE)
    **********************************************************************************************************
    ******************************************* NO LONGER NECESSARY ******************************************

    The Minitest and RSpec tests have been updated, and no longer need to be seeded. Cukes still need seeds.

    **********************************************************************************************************
    **********************************************************************************************************
  END_OF_MESSAGE
  exit 0
end

ActiveRecord::Base.transaction do
  Rake::Task['insdc:countries:import'].invoke
  Rake::Task['record_loader:all'].invoke

  # Here is a proc that will do the seeding.
  handler =
    lambda do |seed_data_file|
      Rails.logger.info("Loading seed data from #{seed_data_file} ...")
      require seed_data_file
      Rails.logger.info("Seed data loaded from #{seed_data_file}")
    end

  # Load all of the files under the 'seeds' directory in their sorted order.  This allows us to define
  # separate files for different sets of seed data and to govern the order they are created in.  For
  # example, property definitions depend on workflows to be present, so they should be ordered *after*
  # those workflows have been created.  Ideally you will be preceeding your seed data with a 4 digit
  # 0-extended sequence number, i.e. 0001_foo.rb is executed *before* 0002_bar.rb.
  Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), %w[seeds *.rb]))).each(&handler)
end
