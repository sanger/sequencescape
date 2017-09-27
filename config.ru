# Rails.root/config.ru
require ::File.expand_path('../config/environment', __FILE__)

run Sequencescape::Application

if Rails.env.profile?
  use Rack::RubyProf, path: 'log/ruby_prof_profile'
end
