unless Rails.env.test?
  Billing.configure do |config|
    config.fields = config.load_file(File.join('config', 'billing'), 'fields')
  end
end
