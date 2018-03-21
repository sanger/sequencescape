namespace :test do
  # lib/tasks/factory_girl.rake
  namespace :factory_girl do
    desc 'Verify that all FactoryGirl factories are valid'
    task lint: :environment do
      require 'factory_girl'
      Dir.glob(File.expand_path(File.join(Rails.root, %w{spec factories ** *.rb}))) do |factory_filename|
        require factory_filename
      end

      if Rails.env.test?
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.cleaning do
          puts 'Linting factories.'
          FactoryGirl.lint
          puts 'Linted'
        end
      else
        system("bundle exec rake factory_girl:lint RAILS_ENV='test'")
      end
    end
  end
end

task test: 'test:factory_girl:lint'
