# frozen_string_literal: true
require Rails.root.join('lib', 'accession')

unless Rails.env.test?
  Accession.configure do |config|
    config.folder = File.join('config', 'accession')
    config.load!
  end
end
