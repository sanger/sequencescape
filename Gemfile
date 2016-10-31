source 'https://rubygems.org'

group :default do
  gem "rails"
  gem 'rails-observers'

  # State machine
  gem "aasm"
  gem "configatron"
  gem "rest-client" # curb substitute.
  gem "formtastic"

  # Caching, primarily of batch.xml Can be removed once our xml interfaces are retired.
  gem 'actionpack-page_caching'
  # Legacy support for parsing XML into params
  gem 'actionpack-xml_parser'

  gem "activerecord-jdbc-adapter", :platforms => :jruby
  gem "activeresource", require: 'active_resource'
  gem "jdbc-mysql", :platforms => :jruby
  gem "mysql", :platforms => :mri
  gem "spreadsheet"
  gem "will_paginate"
  # Will paginate clashes awkwardly with bootstrap
  gem "will_paginate-bootstrap"
  gem 'net-ldap'
  gem 'carrierwave'

  # Provides eg. error_messages_for previously in rails 2, now deprecated.
  gem 'dynamic_form'

  gem 'puma'

  # We pull down a slightly later version as there are commits on head
  # which we depend on, but don't have an official release yet.
  # This is mainly https://github.com/resgraph/acts-as-dag/commit/be2c0179983aaed44fda0842742c7abc96d26c4e
  gem "acts-as-dag", github:'resgraph/acts-as-dag', branch:'5e185dddff6563ee9ee92611555cd9d9a519d280'

  # For background processing
  # Locked for ruby version
  gem "delayed_job_active_record"

  gem "ruby_walk",  ">= 0.0.3",
    :github => "sanger/ruby_walk"

  gem "irods_reader", '>=0.0.2',
    :github => 'sanger/irods_reader'

  # For the API level
  gem "uuidtools"
  gem "sinatra", :require => false
  gem "rack-acceptable", :require => 'rack/acceptable'
  gem "json"
  gem "jrjackson", :platforms => :jruby
  gem "multi_json"
  gem "cancan"

  gem "bunny", "~>0.7"

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
  # Pat of the JS assets pipleine
  gem 'uglifier', '>= 1.0.3'

  # Excel file generation
  gem 'axlsx'
  # Excel file reading
  gem 'roo'

  # Used in XML generation.
  gem 'builder'
end

group :warehouse do
  #the most recent one that actually compiles
  gem "ruby-oci8", :platforms => :mri
  # No ruby-oci8, (Need to use Oracle JDBC drivers Instead)
  #any newer version requires ruby-oci8 => 2.0.1
  gem "activerecord-oracle_enhanced-adapter", '~> 1.4.0'

end

group :development do
  gem "flay", :require => false
  gem "flog", :require => false
  # Detect n+1 queries
  gem "bullet", :require => false
  gem 'pry'
  # Automatically generate documentation
  gem 'yard', :require => false
  # Enforces coding styles and detects some bad practices
  gem 'rubocop', require: false
end

group :test do
  # bundler requires these gems while running tests
  gem "factory_girl", :require => false
  gem "launchy", :require => false
  gem "mocha", :require => false # avoids load order problems
  gem "nokogiri", :require => false
  gem "shoulda", :require => false
  gem "timecop", :require => false
  gem 'simplecov', require: false
end


group :cucumber do
  # We only need to bind cucumber-rails here, the rest are its dependencies which means it should be
  # making sensible choices.  Should ...
  # Yeah well, it doesn't.
  gem "rubyzip", "~>0.9"
  gem "capybara", :require => false
  gem 'mime-types'
  gem "database_cleaner", :require => false
  gem "cucumber-rails", :require => false
  gem "poltergeist"
  gem "webmock"
end

group :deployment do
  gem "psd_logger",
    :github => "sanger/psd_logger"
  gem "gmetric", "~>0.1.3"
  gem "exception_notification"
end
