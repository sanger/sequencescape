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

        # TODO: All these factories should be updated to make them valid
        # Any tests which break as a result should be fixed.
        invalid_factories = [
          :tag_layout,
          :parent_plate_purpose,
          :child_plate_purpose,
          :plate_creation,
          :child_tube_purpose,
          :tube_creation,
          :library_types_request_type,
          :submission__,
          :order_with_submission,
          :tag2_lot
        ]
        ignored = 0
        factories_to_lint = if ENV.fetch('LINT_ALL', false)
                              FactoryGirl.factories.to_a
                            else
                              ignored = invalid_factories.length
                              FactoryGirl.factories.reject do |factory|
                                invalid_factories.include?(factory.name)
                              end
                            end
        begin
          DatabaseCleaner.start
          puts "Linting #{factories_to_lint.length} factories. (Ignored #{ignored})"
          puts 'Use LINT_ALL=true to lint all factories' unless ENV.fetch('LINT_ALL', false)
          FactoryGirl.lint factories_to_lint
          puts 'Linted'
        ensure
          DatabaseCleaner.clean
        end

      else
        system("bundle exec rake factory_girl:lint RAILS_ENV='test'")
      end
    end
  end
end

task test: 'test:factory_girl:lint'
