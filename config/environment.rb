# Load the rails application
$:<< File.join(File.dirname(__FILE__), '..')
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Sequencescape::Application.initialize!
