# Informatics gem
# Models, views and controller helpers for Informatics applications.

# Load and require necessary files
$:.unshift File.dirname(__FILE__)
Dir['lib/informatics/lib/informatics/*.rb'].each { |format| require "informatics/#{File.basename format}" }
