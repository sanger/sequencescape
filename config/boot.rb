# frozen_string_literal: true
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Bootsnap does not purge its cache, which can cause boot-times to increase
# over time. This change will purge the cache every 30 days. In development
# I saw a reduction in boot time from 44 seconds, to 17.
# In production we don't persist the cache between deployments, so wont
# see any benifit, and in practice the purge is unlikely to trigger as its rare
# we go over a month without a release.
# Disable some Rails cops, as Rails isn't actually loaded at this point.
# rubocop:disable Rails/Output, Rails/TimeZone
begin
  time = File.stat('tmp/cache/bootsnap-compile-cache').birthtime

  # If our file was created more than 30 days ago.
  # Note: ActiveSupport isn't loaded yet, so we can't just do 1.month.ago
  # We also avoid using a constant here, as we're in the global namespace
  if time < (Time.now - (60 * 60 * 24 * 30))
    print 'Purging old bootsnap cache...'
    FileUtils.remove_dir('tmp/cache/bootsnap-compile-cache')
    FileUtils.remove_file('tmp/cache/bootsnap-load-path-cache')
    puts ' Done!'
  end
rescue Errno::ENOENT, NotImplementedError
  # Errno::ENOENT
  # File doesn't exist. So no problems here.
  # It *Might* be that the bootsnap-load-path-cache file doesn't exist
  # but again, we don't actually care.
  #
  # NotImplementedError
  # Saw this on travis where 'birthtime' was not implimented
  # In this case we'll just continue.
end
# rubocop:enable Rails/Output, Rails/TimeZone

require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
