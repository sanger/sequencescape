# Rails.root/config.ru
require ::File.expand_path('../config/environment', __FILE__)

run Sequencescape::Application

use Rack::RubyProf, path: 'log/ruby_prof_profile' if Rails.env.profile?
