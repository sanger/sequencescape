# Rails.root/config.ru
require ::File.expand_path('../config/environment',  __FILE__)
run Sequencescape::Application
