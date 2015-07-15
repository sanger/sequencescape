source 'https://rubygems.org'

gem "rails", "~>2.3"

gem "aasm", "~>2.4.0"
gem "configatron"
gem "rest-client" # curb substitute.
gem "fastercsv", "~>1.4.0"
gem "formtastic", "~>1.2.0"
gem "activerecord-jdbc-adapter", ">= 1.2.6", :platforms => :jruby
gem "jdbc-mysql", :platforms => :jruby
gem "mysql", :platforms => :mri
gem "spreadsheet"
gem "will_paginate", "~>2.3.15"
gem 'net-ldap'
gem 'carrierwave', "~>0.4.0"
gem 'jruby-openssl', :platforms => :jruby
gem 'rdoc', '~>2.4.2'

gem 'trinidad', :platforms => :jruby

# This was once a plugin, now it's a gem:
gem 'catch_cookie_exception',
  :github => 'mhartl/catch_cookie_exception'

gem 'sanger_barcode', '~>0.1.1',
  :github => 'sanger/sanger_barcode', :branch => 'ruby-1.8'
# The graph library (1.x only because 2.x uses Rails 3).  This specific respository fixes an issue
# seen in creating asset links during the assign_tags_handler (which blew up in rewire_crossing in the
# gem code).
gem "acts-as-dag",
  :github => "sanger/acts-as-dag", :branch => '38792421_add_dependent_destroy_to_links'

# Better table alterations
gem "alter_table",
  :github => "sanger/alter_table"

# For background processing
gem "delayed_job", '~>2.0.4'

gem "ruby_walk",  ">= 0.0.3",
  :github => "sanger/ruby_walk"

gem "irods_reader", '>=0.0.2',
  :github => 'sanger/irods_reader'

# For the API level
gem "uuidtools"
gem "sinatra", "~>1.1.0"
gem "rack-acceptable", :require => 'rack/acceptable'
# gem "json_pure" #gem "yajl-ruby", :require => 'yajl'
gem "json"
gem "jrjackson"
gem "multi_json"
gem "cancan"

gem "bunny"
#gem "amqp", "~> 0.9.2"

gem "spoon"
# Spoon lets jruby spawn processes, such as the dbconsole. Part of launchy,
# but we'll need it in production if dbconsole is to work

group :warehouse do
  #the most recent one that actually compiles
  gem "ruby-oci8", "1.0.7", :platforms => :mri
  # No ruby-oci8, (Need to use Oracle JDBC drivers Instead)
  #any newer version requires ruby-oci8 => 2.0.1
  gem "activerecord-oracle_enhanced-adapter" , "1.2.3"

end

group :development do
  gem "flay"
  gem "flog"
  gem "roodi"
  gem "rcov", :require => false, :platforms => :mri
  #gem "rcov_rails" # gem only for Rails 3, plugin for Rails 2.3 :-/
  # ./script/plugin install http://svn.codahale.com/rails_rcov
  gem "bullet", "<=4.5.0", :require => false
  gem "ruby-debug"
  gem "utility_belt"
#  gem 'rack-perftools_profiler', '~> 0.1', :require => 'rack/perftools_profiler'
#  gem 'rbtrace', :require => 'rbtrace'
end

group :test do
  # bundler requires these gems while running tests
  # gem "ci_reporter",
  #   :github => "sanger/ci_reporter"
  gem "factory_girl", '~>1.3.1', :require => false
  gem "launchy", :require => false
  gem "mocha", :require => false # avoids load order problems
  gem "nokogiri", :require => false
  gem "shoulda", "~>2.10.0", :require => false
  gem "timecop", :require => false
  gem "treetop", "~>1.2.5", :require => false
  gem 'parallel_tests', :platforms => :mri

  gem "timocratic-test_benchmark", :require => false

  gem 'rgl', :require => false
end

group :cucumber do
  # We only need to bind cucumber-rails here, the rest are its dependencies which means it should be
  # making sensible choices.  Should ...
  # Yeah well, it doesn't.
  gem "rubyzip", "~>0.9"
  gem "capybara", "< 2", :require => false
  gem 'mime-types', '< 2'
  gem "database_cleaner", :require => false
  gem "cucumber", '~> 1.2.1', :require => false
  gem "cucumber-rails", "~>0.3.2", :require => false
  gem "poltergeist", "1.0.3"
end

group :deployment do
  gem "mongrel_cluster", :platforms => :mri
  gem "psd_logger",
    :github => "sanger/psd_logger"
  gem "gmetric", "~>0.1.3"
  gem "trinidad_daemon_extension", :platforms => :jruby
end

