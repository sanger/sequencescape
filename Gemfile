# frozen_string_literal: true

source 'https://rubygems.org'

group :default do
  gem 'bootsnap'
  gem 'rails', '~> 5.1.7'

  # Used by bootstrap, not used directly. Added here to allow us to pin the version.
  # Can be removed once we're no longer compiling assets on the servers.
  # We're currently pinning to keep ruby-racer support. THe suggested alternative
  # mini-racer doesn't compile on the old machines.
  gem 'autoprefixer-rails', '< 9.0.0'

  # State machine
  gem 'aasm'
  gem 'configatron'
  gem 'formtastic'
  gem 'rest-client' # curb substitute.

  # Caching, primarily of batch.xml Can be removed once our xml interfaces are retired.
  gem 'actionpack-page_caching'
  # Legacy support for parsing XML into params
  gem 'actionpack-xml_parser'

  gem 'activeresource'

  # Provides bulk insert capabilities
  gem 'activerecord-import'

  gem 'mysql2', platforms: :mri
  gem 'spreadsheet'
  gem 'will_paginate'
  # Will paginate clashes awkwardly with bootstrap
  gem 'carrierwave'
  gem 'net-ldap'
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

  gem 'irods_reader', '>=0.0.2',
      github: 'sanger/irods_reader'

  # For the API level
  gem 'cancan'
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

  # Bunny is a RabbitMQ client.
  gem 'bunny'

  gem 'bootstrap', '< 4.2.1' # Pinned to 4.2.1 while we are dependent on older GCCs.
  gem 'coffee-rails'
  gem 'jquery-rails'
  gem 'jquery-tablesorter'
  gem 'jquery-ui-rails'
  gem 'sass-rails'
  gem 'select2-rails'
  # Temporarily pin to earlier version
  # Newer versions on font-awesome switch to sassc which will not
  # compile on our older servers due to gcc version. We can update this
  # as soon as we're migrated off the metal.
  gem 'font-awesome-sass', '< 5.0.13'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', platforms: :mri
  # Pat of the JS assets pipleine
  gem 'uglifier', '>= 1.0.3'

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

  # Provides null db adapter, that blocks access to remote database
  # (in our case used for Agresso db in non-production environments)
  gem 'activerecord-nulldb-adapter', require: false

  # Allow simple connection pooling on non-database connections
  # Using it to maintain our warren's of bunnies.
  # Or the connection pool of RabbitMQ channels to get technical
  gem 'connection_pool'

  gem 'rack-cors', require: 'rack/cors'

  # Adds easy conversions between units
  gem 'ruby-units'
end

group :warehouse do
  # Used to connect to oracle databases for some data import
  gem 'ruby-oci8', platforms: :mri
  # No ruby-oci8, (Need to use Oracle JDBC drivers Instead)
  # any newer version requires ruby-oci8 => 2.0.1
  gem 'activerecord-oracle_enhanced-adapter'
end

group :development do
  gem 'flay', require: false
  gem 'flog', require: false
  # Detect n+1 queries
  gem 'bullet'
  # Automatically generate documentation
  gem 'yard', require: false
  # Enforces coding styles and detects some bad practices
  gem 'rubocop', require: false
  gem 'rubocop-performance'
  gem 'rubocop-rspec', require: false
  # MiniProfiler allows you to see the speed of a request conveniently on the page.
  # It also shows the SQL queries performed and allows you to profile a specific block of code.
  gem 'rack-mini-profiler'
  # find unused routes and controller actions by runnung `rake traceroute` from CL
  gem 'traceroute'
  gem 'travis'
end

group :development, :test, :cucumber do
  gem 'pry'
  gem 'pry-stack_explorer'
end

group :profile do
  # Ruby prof requires a separate environments so that is can run in production like mode.
  gem 'ruby-prof'
end

group :test do
  gem 'rspec-rails', require: false
  # Rails performance tests
  gem 'rails-perftest'
  gem 'rspec-collection_matchers' # Provides matchers for dealing with arrays
  gem 'test-prof'
  # Provides json expectations for rspec. Makes test more readable,
  # and test failures more descriptive.
  gem 'rspec-json_expectations', require: false
  # It is needed to use #assigns(attribute) in controllers tests
  gem 'rails-controller-testing'
  # Temporarily lock minitest to a specific version due to incompatibilities
  # with rails versions.
  gem 'minitest', '5.10.3'
  gem 'minitest-profiler'
  gem 'rspec_junit_formatter'
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
  gem 'shoulda-context', require: false
  gem 'shoulda-matchers', require: false
  gem 'simplecov', require: false
  gem 'timecop', require: false
  # Simplifies shared transactions between server and test threads
  # See: http://technotes.iangreenleaf.com/posts/the-one-true-guide-to-database-transactions-with-capybara.html
  # Essentially does two things:
  # - Patches rails to share a database connection between threads while Testing
  # - Pathes rspec to ensure capybara has done its stuff before killing the connection
  gem 'transactional_capybara'
end

group :cucumber do
  gem 'cucumber'
  gem 'cucumber-rails', require: false
  gem 'knapsack'
  gem 'mime-types'
  gem 'rubyzip'
  gem 'webmock'
end

group :deployment do
  gem 'exception_notification'
  gem 'gmetric', '~>0.1.3'
  gem 'whenever', require: false
end
