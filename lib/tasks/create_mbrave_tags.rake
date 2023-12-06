# frozen_string_literal: true
require 'csv'
require 'yaml'
require 'mbrave_tags_creator'

namespace :mbrave do
  desc 'Create MBRAVE tag plates'

  #
  # How to use it:
  # bundle exec rake 'mbrave:create_tag_plates[<login>,<version>]'
  #
  # Example:
  # bundle exec rake 'mbrave:create_tag_plates[admin,v1]'
  task :create_tag_plates, %i[login version] => :environment do |_t, args|
    ActiveRecord::Base.logger.level = 2

    puts 'Creating tag plates for MBRAVE...'
    if args.to_hash.keys.length != 2
      puts 'Arguments: <login> <version> '
      next
    end

    MbraveTagsCreator.process_create_tag_plates(args[:login], args[:version])
  end

  desc 'Create MBRAVE tag groups'

  #
  # How to use it:
  # bundle exec rake 'mbrave:create_tag_groups[<forward_tags.csv>,<reverse_tags.csv>,<version>]'
  #
  # Example:
  # bundle exec rake 'mbrave:create_tag_groups[./forward.csv,./reverse.csv,v3]'
  task :create_tag_groups, %i[forward_file reverse_file version] => :environment do |_t, args|
    ActiveRecord::Base.logger.level = 2

    puts 'Creating tags for MBRAVE...'
    if args.to_hash.keys.length != 3
      puts 'Invalid arguments. Call should be:'
      puts 'rake \'mbrave:create_tag_groups[<forward_tags.csv>,<reverse_tags.csv>,<version>]\''
      next
    end

    MbraveTagsCreator.process_create_tag_groups(args[:forward_file], args[:reverse_file], args[:version])

    next
  end
end
