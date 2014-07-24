require "test_helper"

class BillingEventTest < ActiveSupport::TestCase
  context "A billing event" do
    setup do
      @project = Factory :project, :name => "billed_project"
      @billing_event = Factory :billing_event
    end

    subject { @billing_event }

    should_belong_to :project
    should_have_instance_methods :charge?, :refund?, :charge_internally?

    # should_validate_uniqueness_of :reference
    should_allow_values_for :kind, "charge", "refund", "charge_internally"

    should_validate_presence_of :kind, :reference
    should_validate_presence_of :created_by
    should_validate_presence_of :project
    should_validate_presence_of :quantity
    should_validate_presence_of :request

    should_validate_numericality_of :quantity

    should "Set date and quantity on create" do
      assert_valid @billing_event
      assert_not_nil @billing_event.entry_date
      assert_equal 1, @billing_event.quantity
    end

    context "references" do
      context "must be unique if a charge" do
        setup do
          Factory :billing_event, :reference => "Same"
          assert_raises ActiveRecord::RecordInvalid do
            Factory :billing_event, :reference => "Same"
          end
        end
        should_change("BillingEvent.count", :by => 1) { BillingEvent.count }
      end

      context "must be unique if a charge internally" do
        setup do
          Factory :billing_event, :reference => "Same", :kind => "charge_internally"
          assert_raises ActiveRecord::RecordInvalid do
            Factory :billing_event, :reference => "Same", :kind => "charge_internally"
          end
        end

        should_change("BillingEvent.count", :by => 1) { BillingEvent.count }
      end
      context "may be repeated for refunds" do
        setup do
          Factory :billing_event, :reference => "Same", :quantity => 3
          assert_nothing_raised do
            Factory :billing_event, :reference => "Same", :kind => "refund"
            Factory :billing_event, :reference => "Same", :kind => "refund"
            Factory :billing_event, :reference => "Same", :kind => "refund"
          end
        end

        should_change("BillingEvent.count", :by => 4) { BillingEvent.count }

        should "may be charged internally" do
          assert_nothing_raised do
            Factory :billing_event, :reference => "Same", :kind => "charge_internally"
          end

        end
    end
  end

  context "refunds" do
    context "when no entry exists" do
      setup do
        @request = Factory :request
        assert_raises BillingException::UnchargedRefund do
          @refund_event = BillingEvent.create!(:project => @project,
                                               :reference => "Refund me!",
                                               :kind => "refund",
                                               :created_by => "abc123@example.com")
        end
      end

      should_not_change("BillingEvent.count") { BillingEvent.count }
    end

    context "when an entry exists" do
      setup do
        @request = Factory :request
        assert_nothing_raised do
          assert_equal 1, BillingEvent.count
          @charge = BillingEvent.create(:project => @project,
                                        :reference => "Refund me!",
                                        :request => @request,
                                        :created_by => "abc123@example.com")
          assert_equal 2, BillingEvent.count
          @refund_event = BillingEvent.create(:project => @project,
                                              :reference => "Refund me!",
                                              :kind => "refund",
                                              :request => @request,
                                              :created_by => "abc123@example.com")
        end
      end

      should_change("BillingEvent.count", :by => 2) { BillingEvent.count }
    end

    context "when an entry has been refunded" do
      setup do
        @request = Factory :request
        @charge = BillingEvent.create(:project => @project,
                                      :reference => "Refund me!",
                                      :request => @request,
                                      :created_by => "abc123@example.com")

        assert_nothing_raised do
          @refund_event = BillingEvent.create(:project => @project,
                                              :reference => "Refund me!",
                                              :kind => "refund",
                                              :request => @request,
                                              :created_by => "abc123@example.com")
        end

        assert_raises BillingException::DuplicateRefund do
          @duplicate_refund_event = BillingEvent.create(:project => @project,
                                                        :reference => "Refund me!",
                                                        :kind => "refund",
                                                        :request => @request,
                                                        :created_by => "abc123@example.com")
        end
      end

      should_change("BillingEvent.count", :by => 2) { BillingEvent.count }

      should "only have two entries related to the reference" do
        assert_equal 2, BillingEvent.count(:conditions => {:reference => "Refund me!"})
      end
    end

    context "when a charge has a multiple quantity" do
      setup do
        assert_nothing_raised do
          @request = Factory :request
          @charge = BillingEvent.create(:project => @project,
                                        :reference => "Refund me!",
                                        :kind => "charge",
                                        :request => @request,
                                        :quantity => 5,
                                        :created_by => "abc123@example.com")
        end
      end
      context "and is refunded in one go" do
        setup do
          assert_nothing_raised do
            @refund_event = BillingEvent.create(:project => @project,
                                                :reference => "Refund me!",
                                                :kind => "refund",
                                                :request => @request,
                                                :quantity => 5,
                                                :created_by => "abc123@example.com")
          end
        end

        should_change("BillingEvent.count", :by => 1) { BillingEvent.count }
      end

      context "and is refunded by multiple refunds" do
        setup do
          assert_nothing_raised do
            @refund_event_1 = BillingEvent.create(:project => @project,
                                                  :reference => "Refund me!",
                                                  :kind => "refund",
                                                  :request => @request,
                                                  :quantity => 2,
                                                  :created_by => "abc123@example.com")
            @refund_event_2 = BillingEvent.create(:project => @project,
                                                  :reference => "Refund me!",
                                                  :kind => "refund",
                                                  :request => @request,
                                                  :quantity => 2,
                                                  :created_by => "abc123@example.com")
            @refund_event_3 = BillingEvent.create(:project => @project,
                                                  :reference => "Refund me!",
                                                  :kind => "refund",
                                                  :request => @request,
                                                  :quantity => 1,
                                                  :created_by => "abc123@example.com")
          end
        end

        should_change("BillingEvent.count", :by => 3) { BillingEvent.count }
        should "have no more refunds due" do
          assert_equal 0, @charge.quantity_left_to_refund
        end
      end

      context "and is refunded multiple times and over paid" do
        setup do
          assert_nothing_raised do
            @refund_event_1 = BillingEvent.create(:project => @project,
                                                  :reference => "Refund me!",
                                                  :kind => "refund",
                                                  :request => @request,
                                                  :quantity => 2,
                                                  :created_by => "abc123@example.com")
            @refund_event_2 = BillingEvent.create(:project => @project,
                                                  :reference => "Refund me!",
                                                  :kind => "refund",
                                                  :request => @request,
                                                  :quantity => 1,
                                                  :created_by => "abc123@example.com")
            @refund_event_3 = BillingEvent.create(:project => @project,
                                                  :reference => "Refund me!",
                                                  :kind => "refund",
                                                  :request => @request,
                                                  :quantity => 1,
                                                  :created_by => "abc123@example.com")
          end
          assert_raises BillingException::OverRefund do
            @refund_event_3 = BillingEvent.create(:project => @project,
                                                  :reference => "Refund me!",
                                                  :kind => "refund",
                                                  :request => @request,
                                                  :quantity => 2,
                                                  :created_by => "abc123@example.com")
          end
        end

        should_change("BillingEvent.count", :by => 3) { BillingEvent.count }
        should "have one more refund due" do
          assert_equal 1, @charge.quantity_left_to_refund
        end
      end

    end
  end
end
context "A request with no billing events " do
  setup do
    @request = Factory :request

    @request.asset.aliquots.each do |aliquot|
      aliquot.project = Factory(:project)
      aliquot.save(false)
    end
    @request.asset.aliquots(true)

    @reference = BillingEvent.build_reference(@request)
  end

  teardown do
    BillingEvent.destroy_all
  end

  context "passing" do
    setup do
      BillingEvent.generate_pass_event @request
    end

    should 'not generate any refunds or internal charges' do
      assert_equal [], BillingEvent.refunds_for_reference(@reference)
      assert_nil BillingEvent.charge_internally_for_reference(@reference)
    end

    should "generate a charge event" do
      charge = BillingEvent.charge_for_reference(@reference)
      assert_not_nil charge
      assert_equal @request.initial_project_id, charge.project_id
    end
  end
  context "failing" do
    setup do
      BillingEvent.generate_fail_event @request
    end

    should "generate a charge internally event" do
      assert_nil BillingEvent.charge_for_reference(@reference)
      assert_equal [], BillingEvent.refunds_for_reference(@reference)
      assert BillingEvent.charge_internally_for_reference(@reference)
    end
  end
  context "without an initial project" do
    setup do
      @request.initial_project = nil
      @request.save(false)

      @reference = BillingEvent.build_reference(@request)
    end
    context "passing" do
      setup do
        BillingEvent.generate_pass_event @request
      end

      should 'not generate any refunds or internal charges' do
        assert_equal [], BillingEvent.refunds_for_reference(@reference)
        assert_nil BillingEvent.charge_internally_for_reference(@reference)
      end

      should "generate a charge event" do
        charge = BillingEvent.charge_for_reference(@reference)
        assert_not_nil charge
        assert_equal @request.asset.aliquots.first.project_id, charge.project_id
      end
    end
  end
end
context "A request with no billing events and 2 aliquots " do
  setup do
    @request = Factory :request
    @request.asset.aliquots.create!(:sample => Factory(:sample), :tag => Factory(:tag))
    assert_equal 0, BillingEvent.all.size
  end

  teardown do
    BillingEvent.destroy_all
  end

  context "passing" do
    setup do
      BillingEvent.generate_pass_event @request
    end
    should "generate a charge event per aliquot" do
      BillingEvent.send(:map_for_each_aliquot, @request) do |ai|
        reference = BillingEvent.build_reference(@request, ai)
        event = BillingEvent.charge_for_reference(reference)
        assert event
        assert_equal 0.5,  event.quantity
        assert_equal [], BillingEvent.refunds_for_reference(reference)
        assert_nil BillingEvent.charge_internally_for_reference(reference)
      end
    end
    should_change("BillingEvent.count", :by => 2) { BillingEvent.count }
  end
  context "failing" do
    setup do
      BillingEvent.generate_fail_event @request
    end
    should "generate a charge internally event" do
      BillingEvent.send(:map_for_each_aliquot, @request) do |ai|
        reference = BillingEvent.build_reference(@request, ai)
        assert_nil BillingEvent.charge_for_reference(reference)
        assert_equal [], BillingEvent.refunds_for_reference(reference)
        assert BillingEvent.charge_internally_for_reference(reference)
      end
    end
    should_change("BillingEvent.count", :by => 2) { BillingEvent.count }
  end
end
context "A request" do
  setup do
    @request = Factory :request
    @reference = BillingEvent.build_reference(@request)
  end
  context " with charged  billing event " do
    setup do
      @charged_event = Factory :billing_event, :reference => @reference, :quantity => 10
    end

    should "raise a duplicate charge when passing" do
      assert_raise BillingException::DuplicateCharge do
        BillingEvent.generate_pass_event @request
      end
    end

    context "failing" do
      setup do
        BillingEvent.generate_fail_event @request
      end
      should "generate a charge internally event" do
        assert BillingEvent.charge_internally_for_reference(@reference)
      end

      should "generate a refund event" do
        assert_equal 1, BillingEvent.refunds_for_reference(@reference).size
      end
    end

    context "partially refund" do
      setup do
        Factory :billing_event, :reference => @reference,  :quantity => 7, :kind => "refund"
      end

      should "be refund for the quantity left when failling" do
        new_refunds = BillingEvent.generate_fail_event @request
        assert_equal 1, new_refunds.size
        assert_equal 3, new_refunds.first.quantity
    end
  end
end

  end
end
