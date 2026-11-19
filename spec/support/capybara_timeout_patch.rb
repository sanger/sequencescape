# frozen_string_literal: true

# It is very easy to write slow tests for capybara without realising it.
# Example article:
# https://www.cloudbees.com/blog/faster-rails-tests?utm_source=gem_exception
# Unfortunately the listed gem no longer works, so we write our own. I'm spitting out
# warnings, rather than failures at the moment.
require 'capybara'

module CapybaraTimeoutPatch
  def synchronize(seconds = nil, errors: nil)
    super
  rescue Capybara::ExpectationNotMet => e
    warn "Capybara finder timed-out: #{e.message}" unless seconds < 0.01
    warn Rails.backtrace_cleaner.clean(e.backtrace)
    raise e
  end
end
Capybara::Node::Base.prepend(CapybaraTimeoutPatch)
