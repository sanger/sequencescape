# frozen_string_literal: true

source 'https://rubygems.org'

group :default do
  gem 'bootsnap'
  gem 'concurrent-ruby', '1.3.5'
  gem 'configatron'
  gem 'formtastic'
  gem 'rails', '~> 7.2.0'

  # Previously part of ruby or rails, now separate gems
  gem 'drb'
  gem 'logger'
  gem 'mutex_m'
  gem 'syslog'

  # Connections to external HTTP services
  # See lib/http_clients for examples of usage
  gem 'faraday'
  gem 'faraday-multipart'
  gem 'rest-client' # Deprecated, but still used in some places, replace with Faraday where possible

  # Fix incompatibility with between Ruby 3.1 and Psych 4 (used for yaml)
  # see https://stackoverflow.com/a/71192990
  gem 'psych', '< 4'

  # State machine
  gem 'aasm'
  gem 'after_commit_everywhere', '~> 1.0' # Required by AASM

  # Legacy support for parsing XML into params
  gem 'actionpack-xml_parser'

  # Provides bulk insert capabilities
  gem 'activerecord-import'
  gem 'record_loader', git: 'https://github.com/sanger/record_loader'

  gem 'mysql2', platforms: :mri
  gem 'will_paginate'

  gem 'carrierwave'
  gem 'net-ldap'

  # Will paginate clashes awkwardly with bootstrap
  gem 'will_paginate-bootstrap'

  # Provides eg. error_messages_for previously in rails 2, now deprecated.
  # gem 'dynamic_form'

  gem 'daemons'
  gem 'puma'

  # We pull down a slightly later version as there are commits on head
  # which we depend on, but don't have an official release yet.
  # This is mainly https://github.com/resgraph/acts-as-dag/commit/be2c0179983aaed44fda0842742c7abc96d26c4e
  # ----------------------------
  # NOTE: THIS WAS CHANGED TO payrollhero's master release as it contains a fix for a bug we were
  # experiencing in Rails 6.1
  gem 'acts-as-dag', github: 'payrollhero/acts-as-dag'

  # For background processing
  # Locked for ruby version
  gem 'delayed_job_active_record'

  # For the API level
  gem 'json'
  gem 'multi_json'
  gem 'rack-acceptable', require: 'rack/acceptable'
  gem 'sinatra', require: false
  gem 'uuidtools'

  # Forked and stabilized version of [jsonapi-resources](https://github.com/sanger/jsonapi-resources)
  # for Sanger/PSD projects.
  # Version 0.1.1 was created from the [develop](https://github.com/sanger/jsonapi-resources/tree/develop) branch
  # published, and pinned for Sequencescape compatibility.
  # This version is tested and compatible with Rails 7.1/7.2 and Ruby 3.2/3.3.
  gem 'sanger-jsonapi-resources', '~> 0.1.2'

  # gem 'sanger-jsonapi-resources', github: 'sanger/jsonapi-resources', branch: 'develop'
  gem 'csv', '~> 3.3' # Required by jsonapi-resources, previously part of ruby

  # Wraps bunny with connection pooling and consumer process handling
  gem 'sanger_warren', github: 'sanger/warren', branch: 'master'

  # Use bunny for simple RabbitMQ publishing operations
  gem 'bunny', '>= 2.22.0'

  # Provides message schema encoding and decoding for messages to RabbitMQ
  gem 'avro'

  # Excel file generation
  # Note: We're temporarily using out own for of the project to make use of a few changes
  # which have not yet been merged into a proper release. (Latest release 2.0.1 at time of writing)
  # Future releases SHOULD contain the changes made in our fork, and should be adopted as soon as
  # reasonable once they are available. The next version looks like it may be v3.0.0, so be
  # aware of possible breaking changes.
  gem 'caxlsx'

  # Excel file reading
  gem 'roo'

  # Used in XML generation and parsing
  gem 'builder'
  gem 'rexml' # NOTE: Would be good to remove this due to frequent security issues

  gem 'sanger_barcode_format', github: 'sanger/sanger_barcode_format', branch: 'development'

  gem 'rack-cors', require: 'rack/cors'

  # Adds easy conversions between units
  gem 'ruby-units'

  # Easy colour coding of console output.
  gem 'rainbow'

  # Compile js
  gem 'vite_rails'

  # Authorization
  gem 'cancancan'

  # Send exception notifications via email and other channels
  gem 'exception_notification'

  # Feature flags
  gem 'flipper', '~> 1.0'
  gem 'flipper-active_record', '~> 1.0'
  gem 'flipper-ui', '~> 1.0'

  # For comparing accessioning changes, see EBICheck::Process
  gem 'hashdiff'
end

group :development do
  gem 'rails-erd'

  # Detect n+1 queries
  gem 'bullet'

  # MiniProfiler allows you to see the speed of a request conveniently on the page.
  # It also shows the SQL queries performed and allows you to profile a specific block of code.
  gem 'rack-mini-profiler'

  # find unused routes and controller actions by running `rake traceroute` from CL
  gem 'traceroute'

  # Rails 6 adds listen to assist with reloading
  gem 'listen'
end

group :development, :linting do
  # Enforces coding styles and detects some bad practices
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false

  gem 'prettier_print', require: false
  gem 'syntax_tree', require: false
  gem 'syntax_tree-haml', require: false
  gem 'syntax_tree-rbs', require: false

  # Automatically generate documentation
  gem 'yard', require: false
  gem 'yard-activerecord', '~> 0.0.16', require: false
  gem 'yard-junk', '~> 0.0.9', require: false
end

group :linting, :test do
  gem 'test-prof'
end

group :development, :test, :cucumber do
  gem 'knapsack_pro'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'webmock'
end

group :profile do
  # Ruby prof requires a separate environments so that is can run in production like mode.
  gem 'ruby-prof'
end

group :test do
  gem 'rspec-html-matchers'

  # Rails performance tests
  gem 'rails-perftest'
  gem 'rspec-collection_matchers', require: false # Provides matchers for dealing with arrays
  gem 'rspec-longrun', require: false # Extends scenario logging for more verbose tracking

  # Provides json expectations for rspec. Makes test more readable,
  # and test failures more descriptive.
  gem 'rspec-github', require: false
  gem 'rspec-json_expectations', require: false

  # It is needed to use #assigns(attribute) in controllers tests
  gem 'minitest', '~> 5.0' # TODO: remove constraint when we upgrade to Rails 8, see https://github.com/minitest/minitest/issues/1040
  gem 'minitest-profiler'
  gem 'rails-controller-testing'
end

group :test, :cucumber do
  gem 'capybara'
  gem 'database_cleaner-active_record'
  gem 'database_cleaner-activerecord-seeded_deletion',
      github: 'ManageIQ/database_cleaner-activerecord-seeded_deletion', branch: 'master'
  gem 'factory_bot_rails', require: false
  gem 'jsonapi-resources-matchers', require: false
  gem 'launchy', require: false
  gem 'mocha', require: false # avoids load order problems
  gem 'nokogiri', require: false
  gem 'rspec-rails', '~> 8.0.0', require: false
  gem 'selenium-webdriver', '~> 4.1', require: false
  gem 'shoulda-context', '~> 3.0.0.rc1'
  gem 'shoulda-matchers', '~> 6.0'
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
  gem 'timecop', require: false

  gem 'cucumber_github_formatter'
  gem 'cucumber-rails', require: false
end

group :deployment do
  gem 'slack-notifier'
  gem 'whenever', require: false
end
