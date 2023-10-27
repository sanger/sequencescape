# frozen_string_literal: true

# This ensures that any features tagged with '@api' have the correct Capybara driver.  This means that we can change
# the default driver and these tests will work.
Before('@api') do
  @api_version = '0_5'
  Capybara.current_driver = :rack_test
end

# Ensure that the number of results displayed per page by the API is always 1.
Before('@new-api') { Core::Endpoint::BasicHandler::Paged.results_per_page = 1 }

# Enables a replacement Sample endpoint for the object service tests, disabling it after
class TestSampleEndpoint < Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    has_many(:receptacles, json: 'receptacles', to: 'receptacles', include: %i[labware requests])

    action(:update, to: :standard_update!)
  end

  def self.root
    'samples'
  end

  Core::Abilities::Application.unregistered do
    can(:create, TestSampleEndpoint::Model)
    can(:update, TestSampleEndpoint::Instance)
  end
end

module Core::Endpoint::BasicHandler::EndpointLookup
  %i[object class].each do |name|
    line = __LINE__ + 1

    # rubocop:todo Layout/LineLength
    module_eval(
      "
      def endpoint_for_#{name}_with_object_service(target, *args, &block)
        return ::TestSampleEndpoint if ::Core::Endpoint::BasicHandler::EndpointLookup.testing_api? and (target.is_a?(::Sample) or target == ::Sample)
        endpoint_for_#{name}_without_object_service(target, *args, &block)
      end
      alias_method(:endpoint_for_#{name}_without_object_service, :endpoint_for_#{name})
      alias_method(:endpoint_for_#{name}, :endpoint_for_#{name}_with_object_service)
    ",
      # rubocop:enable Layout/LineLength
      __FILE__,
      line
    )
  end

  def self.testing_api?
    @testing_api
  end

  def self.testing_api=(setting)
    @testing_api = setting
  end
end

Before('@object_service') { Core::Endpoint::BasicHandler::EndpointLookup.testing_api = true }
After('@object_service') { Core::Endpoint::BasicHandler::EndpointLookup.testing_api = false }
