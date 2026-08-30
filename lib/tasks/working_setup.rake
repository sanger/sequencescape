# frozen_string_literal: true
require './lib/oligo_enumerator'

# rubocop:todo Lint/MissingCopEnableDirective
# rubocop:disable Rails/RakeEnvironment, Style/DirectiveScope
# rubocop:enable Lint/MissingCopEnableDirective
namespace :working do
  # We don't want to load Sequencescape just to tell the user that nothing happens.
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

    # rubocop:todo Layout/LineLength
    puts 'Users, studies, projects, suppliers and printers have all been moved to seeds specific to the development environment.'

    # rubocop:enable Layout/LineLength
    puts 'Tag plates, and various stock plates can all be generated through UAT actions.'
  end
end
# rubocop:enable Rails/RakeEnvironment
