# frozen_string_literal: true
next_rails = ENV['BUNDLE_GEMFILE']&.end_with?('GemfileNext')

source 'https://rubygems.org'

group :default do
  gem 'bootsnap'

  if next_rails
    gem 'rails', '~> 6.1.0'
  else
    gem 'rails', '~> 6.0.0'
  end

  # State machine
  gem 'aasm'

  # Required by AASM
  gem 'after_commit_everywhere', '~> 1.0'
  gem 'configatron'
  gem 'formtastic'
  gem 'rest-client' # curb substitute.

  # Legacy support for parsing XML into params
  gem 'actionpack-xml_parser'

  gem 'activeresource'

  # Provides bulk insert capabilities
  gem 'activerecord-import'
  gem 'record_loader'

  gem 'mysql2', platforms: :mri
  gem 'will_paginate'

  gem 'carrierwave'
  gem 'net-ldap'

  # Will paginate clashes awkwardly with bootstrap
  gem 'will_paginate-bootstrap'

  # Provides eg. error_messages_for previously in rails 2, now deprecated.
  gem 'dynamic_form'

  gem 'daemons'
  gem 'puma'

  # We pull down a slightly later version as there are commits on head
  # which we depend on, but don't have an official release yet.
  # This is mainly https://github.com/resgraph/acts-as-dag/commit/be2c0179983aaed44fda0842742c7abc96d26c4e
  gem 'acts-as-dag', github: 'resgraph/acts-as-dag', branch: '5e185dddff6563ee9ee92611555cd9d9a519d280'

  # For background processing
  # Locked for ruby version
  gem 'delayed_job_active_record'

  gem 'irods_reader', '>=0.0.2', github: 'sanger/irods_reader'

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
  gem 'jsonapi-resources', '0.9.0'

  # Wraps bunny with connection pooling ad consumer process handling
  gem 'sanger_warren'

  # Excel file generation
  # Note: We're temporarily using out own for of the project to make use of a few changes
  # which have not yet been merged into a proper release. (Latest release 2.0.1 at time of writing)
  # Future releases SHOULD contain the changes made in our fork, and should be adopted as soon as
  # reasonable once they are available. The next version looks like it may be v3.0.0, so be
  # aware of possible breaking changes.
  gem 'axlsx', github: 'sanger/axlsx', branch: 'v2.0.2sgr'

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
  gem 'webpacker'

  # Authorization
  gem 'cancancan'
end

group :development do
  gem 'rails-erd'

  # Detect n+1 queries
  gem 'bullet'

  # Automatically generate documentation
  gem 'yard', require: false

  # MiniProfiler allows you to see the speed of a request conveniently on the page.
  # It also shows the SQL queries performed and allows you to profile a specific block of code.
  gem 'rack-mini-profiler'

  # find unused routes and controller actions by runnung `rake traceroute` from CL
  gem 'traceroute'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'mini_racer'

  # Pat of the JS assets pipleine
  gem 'uglifier', '>= 1.0.3'

  # Rails 6 adds listen to assist with reloading
  gem 'listen'
end

group :development, :linting do
  # Enforces coding styles and detects some bad practices
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :linting, :test do
  gem 'test-prof'
end

group :development, :test, :cucumber do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'pry-stack_explorer'

  # Asset compilation, js and style libraries
  gem 'bootstrap', '~>4.0' # Pinned as v5 has significant changes
  gem 'font-awesome-sass'
  gem 'jquery-rails'
  gem 'jquery-ui-rails'
  gem 'knapsack_pro'
  gem 'sassc', '2.1.0'
  gem 'sass-rails'
  gem 'select2-rails'
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
  gem 'capybara-selenium'
  gem 'database_cleaner'
  gem 'factory_bot_rails', require: false
  gem 'jsonapi-resources-matchers', require: false
  gem 'launchy', require: false
  gem 'mocha', require: false # avoids load order problems
  gem 'nokogiri', require: false
  gem 'rspec-rails', require: false
  gem 'shoulda'
  gem 'simplecov', require: false
  gem 'timecop', require: false

  # Simplifies shared transactions between server and test threads
  # See: http://technotes.iangreenleaf.com/posts/the-one-true-guide-to-database-transactions-with-capybara.html
  # Essentially does two things:
  # - Patches rails to share a database connection between threads while Testing
  # - Pathes rspec to ensure capybara has done its stuff before killing the connection
  # Causing problems in Rails 6. Remove from Rspec, left in place for cucumber, but can
  # probably be remove there as well.
  gem 'transactional_capybara'

  # Keep webdriver in sync with chrome to prevent frustrating CI failures
  gem 'webdrivers'
end

group :cucumber do
  gem 'cucumber_github_formatter'
  gem 'cucumber-rails', require: false
  gem 'mime-types'
  gem 'rubyzip'
end

group :deployment do
  gem 'exception_notification'
  gem 'slack-notifier'
  gem 'whenever', require: false
  gem 'yard-activerecord', '~> 0.0.16'
end
