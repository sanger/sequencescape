require 'test_helper'

class Pulldown::RequestsTest < ActiveSupport::TestCase
  [ :wgs, :sc, :isc ].each do |request_type|
    context request_type.to_s.upcase do
      setup do
        @request = Factory(:"pulldown_#{request_type}_request")
        @request.asset.aliquots.each { |a| a.update_attributes!(:project => Factory(:project)) }
      end


      should "charge the project when being passed from started" do
        @request.update_attributes!(:state => 'started')
        @request.pass!

        assert_equal(1, BillingEvent.count, "Expected billing events")
        assert_equal(1, BillingEvent.charged_to_project.count, "Expected the project to be charged")
      end
      should "charge the project when being passed from failed" do
        @request.update_attributes!(:state => 'failed')
        @request.change_decision!

        assert_equal(1, BillingEvent.count, "Expected billing events")
        assert_equal(1, BillingEvent.charged_to_project.count, "Expected the project to be charged")
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
        @request.change_decision!  # ... in order to refund them!

        assert_equal(3, BillingEvent.count, "Expected billing events")
        assert_equal(1, BillingEvent.charged_to_project.count, "Expected the project to be charged")
        assert_equal(1, BillingEvent.charged_internally.count, "Expected charge to be internal")
        assert_equal(1, BillingEvent.refunded_to_project.count, "Expected project to be refunded")
      end

      should 'have bait_library_types if appropriate' do
        BillingEvent.all.each do |billing_event|
          if [:sc,:isc].includes?(request_type)
            assert billing_event.request.request_metadata.bait_library.bait_library_type
          else
            assert billing_event.request.request_metadata.bait_library == nil
          end
        end
      end

    end
  end
end
