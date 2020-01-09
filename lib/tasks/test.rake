Rake::Task['test'].clear

task test: :environment do
  $LOAD_PATH << 'test'
  if ENV.key?('TEST')
    Rails::TestUnit::Runner.rake_run([ENV['TEST']])
  else
    test_folders = FileList['test/*'].exclude('test/performance', 'test/*.*')
    Rails::TestUnit::Runner.rake_run(test_folders)
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
      Dir.glob(File.expand_path(File.join(Rails.root, %w{spec factories ** *.rb}))).sort.each do |factory_filename|
        require factory_filename
      end

      if Rails.env.test?
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.cleaning do
          PlateMapGeneration.generate!
          puts 'Linting factories.'
          FactoryBot.lint verbose: true
          puts 'Linted'
        end
      else
        system("bundle exec rake factory_bot:lint RAILS_ENV='test'")
      end
    end
  end
end

task test: ['test:load_cov', 'test:factory_bot:lint']
