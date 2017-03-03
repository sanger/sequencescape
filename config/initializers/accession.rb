require File.join(Rails.root, 'lib', 'accession', 'accession')

unless Rails.env.test?
  Accession.configure do |config|
    config.folder = File.join('config', 'accession')
    config.load!
  end
end
