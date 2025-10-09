# frozen_string_literal: true
require Rails.root.join('lib', 'accession', 'accession')

unless Rails.env.test?
  Accession.configure do |config|
    config.folder = File.join('config', 'accession')
    config.load!
  end
end

# add ena requirement fields here
config.ena_requirement_fields = config_for(:ena_requirement_fields)
