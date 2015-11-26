#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013 Genome Research Ltd.
Sequencescape::Application.configure do
# Edit at your own peril - it's recommended to regenerate this file
# in the future when you upgrade to a newer version of Cucumber.

# IMPORTANT: Setting config.cache_classes to false is known to
# break Cucumber's use_transactional_fixtures method.
# For more information see https://rspec.lighthouseapp.com/projects/16211/tickets/165
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# we don't need :debug unless we're debugging tests
config.log_level = :debug

# Show full error reports and disable caching
# config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

config.active_record.observers = [ :batch_cache_sweeper, :request_observer ]

if defined?(ENV_JAVA)
  ENV_JAVA['http.proxyHost'] = nil
  ENV_JAVA['http.proxyPort'] = nil
  ENV_JAVA['https.proxyHost'] = nil
  ENV_JAVA['https.proxyPort'] = nil
end
end
