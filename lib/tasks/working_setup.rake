require './lib/oligo_enumerator'

namespace :working do
  # We don't want to load Sequencescape just to tell the user that nothing happens.
  # rubocop:disable Rails/RakeEnvironment
  task :basic do
    puts '📣 working:basic no longer generates records. These are made automatically when seeding development.'
  end

  task :printers do
    puts '📣 working:printers no longer generates printers. These are made automatically when seeding development.'
  end

  task :generate_tag_plates do
    puts '📣 working:generate_tag_plates has been removed. Use UAT actions instead.'
  end

  task :setup do
    puts '📣 working:setup is no more.'
    puts 'Users, studies, projects, suppliers and printers have all been moved to seeds specific to the development environment.'
    puts 'Tag plates, and various stock plates can all be generated through UAT actions.'
  end
  # rubocop:enable Rails/RakeEnvironment
end
