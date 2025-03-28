# frozen_string_literal: true

source 'https://rubygems.org'

group :default do
  gem 'bootsnap'
  gem 'concurrent-ruby', '1.3.5'
  gem 'rails', '~> 7.1.5.1'

  # Previously part of ruby or rails, now separate gems
  gem 'drb'
  gem 'logger'
  gem 'mutex_m'
  gem 'syslog'

  # Fix incompatibility with between Ruby 3.1 and Psych 4 (used for yaml)
  # see https://stackoverflow.com/a/71192990
  gem 'psych', '< 4'

  # State machine
  gem 'aasm'

  # Required by AASM
  gem 'after_commit_everywhere', '~> 1.0'
  gem 'configatron'
  gem 'formtastic'
  gem 'rest-client' # curb substitute.

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
  #gem 'dynamic_form'

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

  # API v2
  # Pinned to 0.9.0
  # We apply some monkey patches to this which aren't compatible with later version
  # I've done some preliminary work here:
  # https://github.com/JamesGlover/sequencescape/tree/depfu/update/jsonapi-resources-0.9.5
  # but not only is there a failing test, but performance was tanking in a few places
  # due to not correctly eager loading dependencies on nested resources.

  # Versions above 0.9.0 are incompatible and it is too much work to upgrade at
  # this time. Implementing new patches for updates is not a long term solution
  # as the internals keep changing. However, version 0.9.0 is blocking us from
  # updating rails to version 6.1 . The following steps show the process for an
  # alternative solution:
  # - Fork jsonpi-resources repository
  # - Create a branch off version 0.9.0
  # - Remove the ActionController::ForceSSL module
  # - Load the gem from the branch
  gem 'jsonapi-resources', github: 'sanger/jsonapi-resources', branch: 'develop'

  gem 'csv', '~> 3.3' # Required by jsonapi-resources, previously part of ruby

  # Wraps bunny with connection pooling and consumer process handling
  gem 'sanger_warren'

  # Use bunny for simple RabbitMQ publishing operations
  gem 'bunny', '>= 2.22.0'

  # Provides message schema encoding and decoding for messages to RabbitMQ
  gem 'avro', '~> 1.11.0'

  # Excel file generation
  # Note: We're temporarily using out own for of the project to make use of a few changes
  # which have not yet been merged into a proper release. (Latest release 2.0.1 at time of writing)
  # Future releases SHOULD contain the changes made in our fork, and should be adopted as soon as
  # reasonable once they are available. The next version looks like it may be v3.0.0, so be
  # aware of possible breaking changes.
  gem 'caxlsx'

  # Excel file reading
  gem 'roo'

  # Used in XML generation.
  gem 'builder'

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

  # Feature flags
  gem 'flipper', '~> 0.25.0'
  gem 'flipper-active_record', '~> 0.25.0'
  gem 'flipper-ui', '~> 0.25.0'
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
  gem 'minitest'
  gem 'minitest-profiler'
  gem 'rails-controller-testing'
end

group :test, :cucumber do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_bot_rails', require: false
  gem 'jsonapi-resources-matchers', require: false
  gem 'launchy', require: false
  gem 'mocha', require: false # avoids load order problems
  gem 'nokogiri', require: false
  gem 'rspec-rails', require: false
  gem 'selenium-webdriver', '~> 4.1', require: false
  gem 'shoulda'
  gem 'simplecov', require: false
  gem 'timecop', require: false

  gem 'cucumber_github_formatter'
  gem 'cucumber-rails', require: false
end

group :deployment do
  gem 'exception_notification'
  gem 'slack-notifier'
  gem 'whenever', require: false
end
