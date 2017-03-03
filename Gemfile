source 'https://rubygems.org'

group :default do
  gem 'rails'
  gem 'rails-observers'

  # State machine
  gem 'aasm'
  gem 'configatron'
  gem 'rest-client' # curb substitute.
  gem 'formtastic'

  # Caching, primarily of batch.xml Can be removed once our xml interfaces are retired.
  gem 'actionpack-page_caching'
  # Legacy support for parsing XML into params
  gem 'actionpack-xml_parser'

  gem 'activerecord-jdbc-adapter', :platforms => :jruby
  gem 'activeresource', require: 'active_resource'
  gem 'jdbc-mysql', :platforms => :jruby
  gem 'mysql2', :platforms => :mri
  gem 'spreadsheet'
  gem 'will_paginate'
  # Will paginate clashes awkwardly with bootstrap
  gem 'will_paginate-bootstrap'
  gem 'net-ldap'
  gem 'carrierwave'

  # Provides eg. error_messages_for previously in rails 2, now deprecated.
  gem 'dynamic_form'

  gem 'puma'

  # We pull down a slightly later version as there are commits on head
  # which we depend on, but don't have an official release yet.
  # This is mainly https://github.com/resgraph/acts-as-dag/commit/be2c0179983aaed44fda0842742c7abc96d26c4e
  gem 'acts-as-dag', github:'resgraph/acts-as-dag', branch:'5e185dddff6563ee9ee92611555cd9d9a519d280'

  # For background processing
  # Locked for ruby version
  gem 'delayed_job_active_record'

  gem 'ruby_walk',  '>= 0.0.3',
    :github => 'sanger/ruby_walk'

  gem 'irods_reader', '>=0.0.2',
    :github => 'sanger/irods_reader'

  # For the API level
  gem 'uuidtools'
  gem 'sinatra', require: false
  gem 'rack-acceptable', require: 'rack/acceptable'
  gem 'json'
  gem 'jrjackson', platforms: :jruby
  gem 'multi_json'
  gem 'cancan'

  # MarchHare and Bunny are both RabbitMQ clients.
  # While bunny does work with Jruby, it is not recommended
  # and we ran into a few issues following the Rails 4 upgrade.
  # Both have very similar API's and so we switch between then
  # depending on environment.
  gem 'march_hare', "~> 2.18.0", platforms: :jruby
  gem 'bunny', platforms: :mri

  gem 'spoon'
  # Spoon lets jruby spawn processes, such as the dbconsole. Part of launchy,
  # but we'll need it in production if dbconsole is to work

  gem 'jquery-rails'
  gem 'jquery-ui-rails'
  gem 'jquery-tablesorter'
  gem 'bootstrap-sass'
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'select2-rails'
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
  # Used to connect to oracle databases for some data import
  gem 'ruby-oci8', platforms: :mri
  # No ruby-oci8, (Need to use Oracle JDBC drivers Instead)
  # any newer version requires ruby-oci8 => 2.0.1
  gem 'activerecord-oracle_enhanced-adapter', '~> 1.6.0'
end

group :development do
  gem 'flay', require: false
  gem 'flog', require: false
  # Detect n+1 queries
  gem 'bullet', require: false
  gem 'pry'
  # Automatically generate documentation
  gem 'yard', require: false
  # Enforces coding styles and detects some bad practices
  gem 'rubocop', require: false
  # MiniProfiler allows you to see the speed of a request conveniently on the page.
  # It also shows the SQL queries performed and allows you to profile a specific block of code.
  gem 'rack-mini-profiler'
end

group :test do
  gem 'rspec-rails', require: false
  # Simplifies shared transactions between server and test threads
  # See: http://technotes.iangreenleaf.com/posts/the-one-true-guide-to-database-transactions-with-capybara.html
  # Essentially does two things:
  # - Patches rails to share a database connection between threads while Testing
  # - Pathes rspec to ensure capybara has done its stuff before killing the connection
  gem 'transactional_capybara'
  # Rails performance tests
  gem 'rails-perftest'
  # Provides json expectations for rspec. Makes test more readable,
  # and test failures more descriptive.
  gem 'rspec-json_expectations', require: false
end

group :test,:cucumber do
  gem 'factory_girl', require: false
  gem 'launchy', require: false
  gem 'mocha', require: false # avoids load order problems
  gem 'nokogiri', require: false
  gem 'shoulda', require: false
  gem 'timecop', require: false
  gem 'simplecov', require: false
  gem 'database_cleaner'
end

group :cucumber do
  gem 'rubyzip', '~>0.9'
  gem 'capybara'
  gem 'mime-types'
  gem 'cucumber-rails', require: false
  gem 'poltergeist'
  gem 'webmock'
  gem 'knapsack'
end

group :deployment do
  gem 'psd_logger',
    :github => 'sanger/psd_logger'
  gem 'gmetric', '~>0.1.3'
  gem 'exception_notification'
end
