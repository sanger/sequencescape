namespace :test do
  # lib/tasks/factory_girl.rake
  namespace :factory_girl do
    desc 'Verify that all FactoryGirl factories are valid'
    task lint: :environment do
      require 'factory_girl'
      require File.expand_path(File.join(Rails.root, %w{test factories.rb}))
      Dir.glob(File.expand_path(File.join(Rails.root, %w{test factories ** *.rb}))) do |factory_filename|
       require factory_filename
      end
      Dir.glob(File.expand_path(File.join(Rails.root, %w{test lib sample_manifest_excel factories ** *.rb}))) do |factory_filename|
       require factory_filename
      end

      if Rails.env.test?
        begin
          DatabaseCleaner.start
          puts 'Linting factories.'
          FactoryGirl.lint
          puts 'Linted'
        ensure
          DatabaseCleaner.clean, except: %w(ar_internal_metadata)
        end

      else
        system("bundle exec rake factory_girl:lint RAILS_ENV='test'")
      end
    end
  end
end

task test: 'test:factory_girl:lint'
