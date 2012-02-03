require 'test_helper'

class Pulldown::RequestsTest < ActiveSupport::TestCase
  [ :wgs, :sc, :isc ].each do |request_type|
    context request_type.to_s.upcase do
      setup do
        @request = Factory(:"pulldown_#{request_type}_request")
        @request.asset.aliquots.each { |a| a.update_attributes!(:project => Factory(:project)) }
      end

      [ 'started', 'failed' ].each do |initial_state|
        should "charge the project when being passed from #{initial_state}" do
          @request.update_attributes!(:state => initial_state)
          @request.pass!

          assert_equal(1, BillingEvent.count, "Expected billing events")
          assert_equal(1, BillingEvent.charged_to_project.count, "Expected the project to be charged")
        end
      end

      should 'charge internally when failing from started' do
        @request.update_attributes!(:state => 'started')
        @request.fail!

        assert_equal(1, BillingEvent.count, "Expected billing events")
        assert_equal(1, BillingEvent.charged_internally.count, "Expected charge to be internal")
      end

      should 'refund the project when failing from passed' do
        @request.start! # Start the request ...
        @request.pass!  # ... so that the charges can be made against the project ...
        @request.fail!  # ... in order to refund them!

        assert_equal(3, BillingEvent.count, "Expected billing events")
        assert_equal(1, BillingEvent.charged_to_project.count, "Expected the project to be charged")
        assert_equal(1, BillingEvent.charged_internally.count, "Expected charge to be internal")
        assert_equal(1, BillingEvent.refunded_to_project.count, "Expected project to be refunded")
      end
    end
  end
end
