require File.expand_path(File.join(File.dirname(__FILE__), 'fake_sinatra_service.rb'))

class FakeSampleValidationService < FakeSinatraService
  def initialize(*args, &block)
    super
    configatron.pac_bio_instrument_api = "http://#{host}:#{port}/SampleSheet/Validate"
  end

  def return_values
    @return_values ||= []
  end

  def clear
    @return_values = []
  end

  def next!
    self.return_values.pop
  end

  def return_value(return_value)
    self.return_values.push(return_value)
  end

  def service
    Service
  end

  class Service < FakeSinatraService::Base
    post('/SampleSheet/Validate') do
      json  = { 'Success' => FakeSampleValidationService.instance.next! }
      headers('Content-Type' => 'application/json')
      body(json.to_json)
    end
  end
end

FakeSampleValidationService.install_hooks(self, '@sample_validation_service')

