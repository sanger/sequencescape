source 'https://rubygems.org'

group :default do
  gem "rails"
  gem 'rails-observers'

  gem "aasm"
  gem "configatron"
  gem "rest-client" # curb substitute.
  gem "formtastic"

  # By default formtastic applies styles which clash with bootstrap.
  # The configuration provides no means of overriding this
  # Fixing it means monkey patches, or extensive re-implementation
  # formtastic-bootstrap is essentially these cludgy fixes in a gem
  # Fixing things proper means actually updating formtastic
  # gem "formtastic-bootstrap"

  gem "activerecord-jdbc-adapter", :platforms => :jruby
  gem "jdbc-mysql", :platforms => :jruby
  gem "mysql", :platforms => :mri
  gem "spreadsheet"
  gem "will_paginate"
  # Will paginate clashes awkwardly with bootstrap
  gem "will_paginate-bootstrap"
  gem 'net-ldap'
  gem 'carrierwave'
  gem 'jruby-openssl', :platforms => :jruby

  # Provides eg. error_messages_for previously in rails 2, now deprecated.
  gem 'dynamic_form'

  gem 'trinidad', :platforms => :jruby

  gem 'sanger_barcode', '~>0.2',
    :github => 'sanger/sanger_barcode', :branch => 'ruby-1.9'
  # The graph library (1.x only because 2.x uses Rails 3).  This specific respository fixes an issue
  # seen in creating asset links during the assign_tags_handler (which blew up in rewire_crossing in the
  # gem code).
  gem "acts-as-dag"

  # Better table alterations
  # gem "alter_table",
  #   :github => "sanger/alter_table"

  # For background processing
  # Locked for ruby version
  gem "delayed_job_active_record"

  gem "ruby_walk",  ">= 0.0.3",
    :github => "sanger/ruby_walk"

  gem "irods_reader", '>=0.0.2',
    :github => 'sanger/irods_reader'

  # For the API level
  gem "uuidtools"
  gem "sinatra", "~>1.1.0", :require => false
  gem "rack-acceptable", :require => 'rack/acceptable'
  # gem "json_pure" #gem "yajl-ruby", :require => 'yajl'
  gem "json"
  gem "jrjackson"
  gem "multi_json"
  gem "cancan"

  gem "bunny", "~>0.7"
  #gem "amqp", "~> 0.9.2"

  gem "spoon"
  # Spoon lets jruby spawn processes, such as the dbconsole. Part of launchy,
  # but we'll need it in production if dbconsole is to work

  gem "jquery-rails"
  gem 'jquery-ui-rails'
  gem "jquery-tablesorter"
  gem 'bootstrap-sass'
  gem 'sass-rails'
  gem 'coffee-rails'
  gem "select2-rails"
  # gem 'font-awesome-sass'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyrhino'

  gem 'uglifier', '>= 1.0.3'
end

group :warehouse do
  #the most recent one that actually compiles
  gem "ruby-oci8", :platforms => :mri
  # No ruby-oci8, (Need to use Oracle JDBC drivers Instead)
  #any newer version requires ruby-oci8 => 2.0.1
  gem "activerecord-oracle_enhanced-adapter" , "1.2.3"

end

group :development do
  gem "flay", :require => false
  gem "flog", :require => false
  gem "bullet", :require => false
  gem "debugger", :platforms => :mri
  gem "ruby-debug", :platforms => :jruby
  gem 'pry'
  gem 'rdoc', :require => false
end

group :test do
  # bundler requires these gems while running tests
  gem "factory_girl", :require => false
  gem "launchy", :require => false
  gem "mocha", :require => false # avoids load order problems
  gem "nokogiri", :require => false
  gem "shoulda", :require => false
  gem "timecop", :require => false
  gem "treetop", :require => false
  # gem 'parallel_tests', :require => false
  gem 'rgl', :require => false
end

group :cucumber do
  # We only need to bind cucumber-rails here, the rest are its dependencies which means it should be
  # making sensible choices.  Should ...
  # Yeah well, it doesn't.
  gem "rubyzip", "~>0.9"
  gem "capybara", :require => false
  gem 'mime-types'
  gem "database_cleaner", :require => false
  gem "cucumber", :require => false
  gem "cucumber-rails", :require => false
  gem "poltergeist"
end

group :deployment do
  gem "psd_logger",
    :github => "sanger/psd_logger"
  gem "gmetric", "~>0.1.3"
  gem "exception_notification"
  gem "trinidad_daemon_extension", :platforms => :jruby
end

