# frozen_string_literal: true
# Rails.root/config.ru
require File.expand_path('config/environment', __dir__)

run Rails.application

use Rack::RubyProf, path: 'log/ruby_prof_profile' if Rails.env.profile?
