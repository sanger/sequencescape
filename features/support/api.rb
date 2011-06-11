# This ensures that any features tagged with '@api' have the correct Capybara driver.  This means that we can change
# the default driver and these tests will work.
Before('@api') do
  @api_version = "0_5"
  Capybara.current_driver = :rack_test
end

# Ensure that the number of results displayed per page by the API is always 1.
Before('@new-api') do
  ::Core::Endpoint::BasicHandler::Paged.results_per_page = 1
end

# Enables a replacement Sample endpoint for the object service tests, disabling it after
class TestSampleEndpoint < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    has_many(
      :sample_tubes, :json => 'sample_tubes', :to => 'sample_tubes',
      :include => [ :library_tubes, :requests ]
    )

    action(:update, :to => :standard_update!)
  end

  def self.root
    'samples'
  end
end
class ::Api::EndpointHandler
  def endpoint_for_object(*args, &block)
    self.class.endpoint || super
  end

  def endpoint_for_class(*args, &block)
    self.class.endpoint || super
  end

  def self.endpoint=(endpoint)
    @endpoint = endpoint
  end

  def self.endpoint
    @endpoint
  end
end

Before('@object_service') do
  ::Api::EndpointHandler.endpoint = ::TestSampleEndpoint
end
After('@object_service') do
  ::Api::EndpointHandler.endpoint = nil
end
