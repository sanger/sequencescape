# frozen_string_literal: true
require Rails.root.join('lib', 'accession')

unless Rails.env.test?
  Accession.configure do |config|
    config.folder = File.join('config', 'accession')
    config.load!
  end
end

# add ena requirement fields here
ena_requirement_fields = YAML.load_file('config/ena_requirement_fields.yml')
Rails.application.config.ena_requirement_fields = ena_requirement_fields.with_indifferent_access
