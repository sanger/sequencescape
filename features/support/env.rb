# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a 
# newer version of cucumber-rails. Consider adding your own code to a new file 
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

require 'rubygems'
 
ENV["RAILS_ENV"] ||= "cucumber"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')

require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support
require 'cucumber/rails/world'
require 'cucumber/rails/active_record'
require 'cucumber/web/tableish'


require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'
require 'cucumber/rails/capybara_javascript_emulation' # Lets you click links with onclick javascript handlers without using @culerity or @javascript
require 'timecop'



Capybara.save_and_open_page_path = "tmp/capybara"

# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
Capybara.default_selector = :css

# This is a monkey patch for capybara =0.3.9
# If we upgrade to ~>0.4.0 then this monkey patch needs to go!
# Add better support for Capybara parallel testing using server port numbering
if ENV['TEST_ENV_NUMBER']
  class Capybara::Server
    def find_available_port
      @port = 11000 + (ENV['TEST_ENV_NUMBER'].to_i * 100)
      @port += 1 while is_port_open?(@port) and not is_running_on_port?(@port)
    end
  end
end

# If you set this to false, any error raised from within your app will bubble 
# up to your step definition and out to cucumber unless you catch it somewhere
# on the way. You can make Rails rescue errors and render error pages on a
# per-scenario basis by tagging a scenario or feature with the @allow-rescue tag.
#
# If you set this to true, Rails will rescue all errors and render error
# pages, more or less in the same way your application would behave in the
# default production environment. It's not recommended to do this for all
# of your scenarios, as this makes it hard to discover errors in your application.
ActionController::Base.allow_rescue = false

# If you set this to true, each scenario will run in a database transaction.
# You can still turn off transactions on a per-scenario basis, simply tagging 
# a feature or scenario with the @no-txn tag. If you are using Capybara,
# tagging with @culerity or @javascript will also turn transactions off.
#
# If you set this to false, transactions will be off for all scenarios,
# regardless of whether you use @no-txn or not.
#
# Beware that turning transactions off will leave data in your database 
# after each scenario, which can lead to hard-to-debug failures in 
# subsequent scenarios. If you do this, we recommend you create a Before
# block that will explicitly put your database in a known state.
Cucumber::Rails::World.use_transactional_fixtures = true
# How to clean your database when transactions are turned off. See
# http://github.com/bmabey/database_cleaner for more info.
if defined?(ActiveRecord::Base)
  begin
    require 'database_cleaner'

    # Here's a database cleaner strategy that builds on truncation: it truncates all but the 
    # seeded tables, which it deletes everything from except what was original in the seeded data.
    #
    # It's not going to be perfect, in that any changes to the seed data will remain, but it should
    # suffice to get our features running properly.  Note that if you're messing with the seed data
    # then you're certainly doing something wrong!
    require 'database_cleaner/active_record/truncation'
    class TruncateWithinReason < DatabaseCleaner::ActiveRecord::Truncation
      def initialize(tables_to_unique_columns)
        @seeded = determine_seeded_tables(standardise_unique_columns_for_tables(tables_to_unique_columns))
        super(:except => @seeded.keys)
      end

      def clean
        super
        clean_seeded_tables
      end

      # Ensures that there is a Hash which returns 'id' for undefined tables, otherwise it returns
      # a specific case, including the 'schema_migration' table which should use 'version'.
      def standardise_unique_columns_for_tables(tables_to_unique_columns)
        Hash.new { |h,k| h[k] = 'id' }.tap do |standard_unique_columns|
          standard_unique_columns['schema_migrations'] = 'version'
          standard_unique_columns.merge!(tables_to_unique_columns)
        end
      end
      private :standardise_unique_columns_for_tables

      # Determine all of the current rows in the seeded tables.  This way we can destroy any new rows
      # that are added by any scenarios after they have been run.  Note that "uniqueness" is done
      # based on specific columns for the tables, which may be the ID but might not for some tables.
      def determine_seeded_tables(tables_to_unique_columns)
        Hash[
          connection_klass.connection.select_all('SHOW TABLE STATUS WHERE Rows > 0').map do |row|
            table_name    = row['Name']
            unique_columns = Array(tables_to_unique_columns[table_name])

            unique_identifiers_in_table = connection_klass.connection.select_all("SELECT #{unique_columns.join(',')} FROM #{table_name}").map do |results|
              Hash[unique_columns.map { |unique_column| [unique_column, results[unique_column]] }]
            end

            if unique_identifiers_in_table.blank?
              nil
            elsif unique_columns.size == 1
              [ table_name, "#{unique_columns.first} NOT IN (#{ unique_identifiers_in_table.map(&:values).flatten.join(',') })" ]
            else
              # There are multiple conditions for a row to be unique so we need to AND them, and then OR
              # the conditions for each row to correctly identify what needs removing.
              and_conditions = unique_identifiers_in_table.map { |single_row| "(#{single_row.map { |k,v| "#{k}=#{v}" }.join(" AND ")})" }
              [ table_name, and_conditions.join(" OR ") ]
            end
          end.compact
        ]
      end
      private :determine_seeded_tables

      def clean_seeded_tables
        @seeded.each do |table, delete_conditions|
          connection_klass.connection.update("DELETE FROM `#{table}` WHERE #{delete_conditions}")
        end
      end
      private :clean_seeded_tables
    end

    # Some of tables have, effectively, composite keys
    DatabaseCleaner.strategy = TruncateWithinReason.new(
      'roles_users' => [ 'role_id', 'user_id' ]
    )
  rescue LoadError => ignore_if_database_cleaner_not_present
  end
end

After do |s|
  # If we're lost in time then we need to return to the present...
  Timecop.return
  
  # Tell Cucumber to quit after this scenario is done - if it failed.
  # Cucumber.wants_to_quit = true if s.failed?
end
