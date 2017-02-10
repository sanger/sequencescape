# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

# This ensures that any features tagged with '@api' have the correct Capybara driver.  This means that we can change
# the default driver and these tests will work.
Before('@api') do
  @api_version = '0_5'
  Capybara.current_driver = :rack_test
end

# Ensure that the number of results displayed per page by the API is always 1.
Before('@new-api') do
  ::Core::Endpoint::BasicHandler::Paged.results_per_page = 1
end

# Enables a replacement Sample endpoint for the object service tests, disabling it after
class TestSampleEndpoint < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    has_many(
      :sample_tubes, json: 'sample_tubes', to: 'sample_tubes',
                     include: [:library_tubes, :requests]
    )

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

module ::Core::Endpoint::BasicHandler::EndpointLookup
  [:object, :class].each do |name|
    line = __LINE__ + 1
    module_eval("
      def endpoint_for_#{name}_with_object_service(target, *args, &block)
        return ::TestSampleEndpoint if ::Core::Endpoint::BasicHandler::EndpointLookup.testing_api? and (target.is_a?(::Sample) or target == ::Sample)
        endpoint_for_#{name}_without_object_service(target, *args, &block)
      end
      alias_method_chain(:endpoint_for_#{name}, :object_service)
    ", __FILE__, line)
  end

  def self.testing_api?
    @testing_api
  end

  def self.testing_api=(setting)
    @testing_api = setting
  end
end

Before('@object_service') do
  ::Core::Endpoint::BasicHandler::EndpointLookup.testing_api = true
end
After('@object_service') do
  ::Core::Endpoint::BasicHandler::EndpointLookup.testing_api = false
end
