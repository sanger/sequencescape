# frozen_string_literal: true
Rake::Task['test'].clear

task test: :environment do
  $LOAD_PATH << 'test'
  if ENV.key?('TEST')
    Rails::TestUnit::Runner.run([ENV['TEST']])
  else
    test_folders = FileList['test/*'].exclude('test/performance', 'test/*.*')
    Rails::TestUnit::Runner.run(test_folders)
  end
end

namespace :test do
  # Code coverage needs to be one of the very first things you do
  # as coverage is only tracked on first run. As a result, if we don't
  # initialize it before running our factory linters we MASSIVELY under-report
  # coverage. Any code paths hit by the linters will have a coverage of zero,
  # regardless of subsequent processing.
  task load_cov: :environment do
    require 'simplecov'
  end

  namespace :factory_bot do
    desc 'Verify that all FactoryBot factories are valid'
    task lint: :environment do
      require 'factory_bot'

      Rails.root.join('spec/factories/').glob('**/*.rb').sort.each { |factory_filename| require factory_filename }

      if Rails.env.test?
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.cleaning do
          PlateMapGeneration.generate!
          FactoryBot.lint
          puts 'Linted'
        end
      else
        system("bundle exec rake factory_bot:lint RAILS_ENV='test'")
      end
    end
  end
end

task test: %w[test:load_cov test:factory_bot:lint]
