require 'rails_helper'

RSpec.describe Request do
  include AASM
  context 'A Request' do
    context 'while scoping with #for_order_including_submission_based_requests' do
      setup do
        @study = create :study
        @project = create :project

        @asset = create :empty_sample_tube
        @asset.aliquots.create!(sample: create(:sample, studies: [@study]))

        @asset2 = create :empty_sample_tube
        @asset2.aliquots.create!(sample: create(:sample, studies: [@study]))

        @order1 = create :order_with_submission, study: @study, assets: [@asset], project: @project
        @order2 = create :order,  study: @study, assets: [@asset], project: @project
        @order3 = create :order,  study: @study, assets: [@asset2], project: @project
        @order4 = create :order_with_submission,  study: @study, assets: [@asset2], project: @project

        @submission = @order1.submission
        @submission.orders.push(@order2)
        @submission.orders.push(@order3)

        @sequencing_request = create :request_with_sequencing_request_type, submission: @submission
        @request = create :request, order: @order1, asset: @asset, submission: @submission
        @request2 = create :request, order: @order2, submission: @submission

        @request3 = create :request, order: @order4, submission: @order4.submission
        @sequencing_request2 = create :request_with_sequencing_request_type, submission: @order4.submission
      end
      it 'the sequencing requests are included' do
        assert_equal 1, @order1.requests.length
        assert_equal 1, @order2.requests.length
        assert_equal 0, @order3.requests.length
        assert_equal 3, @submission.requests.length
        assert_equal 2, @submission.requests.for_order_including_submission_based_requests(@order1).length
        assert_equal 2, @submission.requests.for_order_including_submission_based_requests(@order2).length
      end
      it 'an order without requests should at least find the sequencing requests' do
        assert_equal 1, @submission.requests.for_order_including_submission_based_requests(@order3).length
      end

      it 'when filtering from submission and scoping with an order of another submission, none of the requests are included' do
        assert_equal 0, @order4.submission.requests.for_order_including_submission_based_requests(@order1).length
        assert_equal 0, @order4.submission.requests.for_order_including_submission_based_requests(@order2).length
        assert_equal 0, @order4.submission.requests.for_order_including_submission_based_requests(@order3).length
        assert_equal 0, @submission.requests.for_order_including_submission_based_requests(@order4).length
      end

      it 'requests from other submission behave independently' do
        assert_equal 1, @order4.requests.length
        assert_equal 2, @order4.submission.requests.length
        assert_equal 2, @order4.submission.requests.for_order_including_submission_based_requests(@order4).length
      end

      it 'can be used as any other request scope' do
        assert_equal 2, Request.for_order_including_submission_based_requests(@order1).length
        assert_equal 2, Request.for_order_including_submission_based_requests(@order2).length
        assert_equal 1, Request.for_order_including_submission_based_requests(@order3).length
        assert_equal 2, Request.for_order_including_submission_based_requests(@order4).length
      end
    end

    context '#next_request' do
      setup do
        @genotyping_request_type = create :request_type, name: 'genotyping'
        @cherrypick_request_type = create :request_type, name: 'cherrypick', target_asset_type: nil
        @submission = FactoryHelp.submission(request_types: [@cherrypick_request_type, @genotyping_request_type].map(&:id), asset_group_name: 'to avoid asset errors')
        @item = create :item, submission: @submission

        @genotype_pipeline = create :pipeline, name: 'genotyping pipeline', request_types: [@genotyping_request_type]
        @cherrypick_pipeline = create :pipeline, name: 'cherrypick pipeline', request_types: [@cherrypick_request_type], next_pipeline_id: @genotype_pipeline.id, asset_type: 'LibraryTube'

        @request1 = create(
          :request_without_assets,
          item: @item,
          asset: create(:sample_tube),
          target_asset: nil,
          submission: @submission,
          request_metadata_attributes: {},
          request_type: @cherrypick_request_type
        )
      end
      context 'with valid input' do
        setup do
          @request2 = create :request, item: @item, submission: @submission, request_type: @genotyping_request_type
        end
        it 'return the correct next request' do
          assert_equal [@request2], @request1.next_requests(@cherrypick_pipeline)
        end
      end

      context 'where asset hasnt been created for second request' do
        setup do
          @request2 = create :request, asset: nil, item: @item, submission: @submission, request_type: @genotyping_request_type
        end
        it 'return the correct next request' do
          assert_equal [@request2], @request1.next_requests(@cherrypick_pipeline)
        end
      end

      context '#associate_pending_requests_for_downstream_pipeline' do
        setup do
          @request2 = create :request_without_assets, asset: nil, item: @item, submission: @submission, request_type: @genotyping_request_type
          @request3 = create :request_without_assets, asset: nil, item: @item, submission: @submission, request_type: @genotyping_request_type

          @batch = @cherrypick_pipeline.batches.create!(requests: [@request1])

          @request1.reload
          @request2.reload
        end
        it 'set the target asset of request 1 to be the asset of request 2' do
          assert_equal @request1.target_asset, @request2.asset
        end
      end
    end

    context '#copy' do
      setup do
        @study = create :study
        @request_type = create :request_type
        @item         = create :item
        @request = create :request, request_type: @request_type, study: @study, item: @item, state: 'failed'
        @new_request = @request.copy
      end

      it 'return same properties' do
        @request.reload
        @new_request.reload
        original_attributes = @request.request_metadata.attributes.merge('id' => nil, 'request_id' => nil, 'updated_at' => nil)
        copied_attributes   = @new_request.request_metadata.attributes.merge('id' => nil, 'request_id' => nil, 'updated_at' => nil)
        assert_equal original_attributes, copied_attributes
      end

      it 'return same item_id' do
        assert_equal @request.item_id, @new_request.item_id
      end

      it 'remove target_asset' do
        assert_nil @new_request.target_asset_id
      end

      it 'be pending' do
        assert @new_request.pending?
      end
    end

    context '#after_create' do
      context 'successful' do
        let(:study) { create :study }
        let(:request) { create :request, study: study }

        it 'not have ActiveRecord errors' do
          expect(request.errors).to be_empty
        end

        it 'have request as valid' do
          expect(request).to be_valid
        end
      end
    end

    context '#state' do
      setup do
        @study = create :study
        @item  = create :item
        @request = create :request_suitable_for_starting, study: @study, item: @item
        @user = create :admin
        @user.has_role 'owner', @study
      end

      context 'when a new request is created' do
        it "return the default state 'pending'" do
          assert_equal 'pending', @request.state
        end
      end

      context 'when started' do
        setup do
          @request.start!
        end

        it "return 'Started'" do
          assert_equal 'started', @request.state
        end

        it 'not be pending' do
          assert_equal false, @request.pending?
        end

        it 'not be passed' do
          assert_equal false, @request.passed?
        end

        it 'not be failed' do
          assert_equal false, @request.failed?
        end

        it 'be started' do
          assert @request.started?
        end

        context 'allow transition' do
          it 'to pass' do
            @request.state = 'started'
            @request.pass!
          end

          it 'to fail' do
            @request.state = 'started'
            @request.fail!
          end
        end
      end

      context 'when passed' do
        setup do
          @request.state = 'started'
          @request.pass!
        end

        it "return status of 'passed'" do
          assert_equal 'passed', @request.state
        end

        it 'not be pending' do
          assert_equal false, @request.pending?
        end

        it 'not be failed' do
          assert_equal false, @request.failed?
        end

        it 'not be started' do
          assert_equal false, @request.started?
        end

        it 'be passed' do
          assert @request.passed?
        end

        context 'do not allow the transition' do
          setup do
            @request.state = 'passed'
          end

          it 'to started' do
            # At least we'll know when and where it's blowing up.
            expect { @request.start! }.to raise_error(AASM::InvalidTransition)
          end
        end
      end

      context 'when failed' do
        setup do
          @request.state = 'started'
          @request.fail!
        end

        it "return status of 'failed'" do
          assert_equal 'failed', @request.state
        end

        it 'not be pending' do
          assert_equal false, @request.pending?
        end

        it 'not be passed' do
          assert_equal false, @request.passed?
        end

        it 'not be started' do
          assert_equal false, @request.started?
        end

        it 'be failed' do
          assert @request.failed?
        end

        it 'not allow transition to passed' do
          expect { @request.pass! }.to raise_error(AASM::InvalidTransition)
          expect { @request.retrospective_pass! }.not_to raise_error
        end
      end
    end

    context '#open and #closed' do
      setup do
        @open_states = ['pending', 'started']
        @closed_states = ['passed', 'failed', 'cancelled']

        @all_states = @open_states + @closed_states

        @all_states.each do |state|
          create :request, state: state
        end

        assert_equal @all_states.size, Request.count
      end
      context 'open requests' do
        it 'total right number' do
          assert_equal @open_states.size, Request.opened.count
        end
      end
      context 'closed requests' do
        it 'total right number' do
          assert_equal @closed_states.size, Request.closed.count
        end
      end
    end

    context '#ready?' do
      setup do
        @library_creation_request = create(:library_creation_request_for_testing_sequencing_requests)
      end

      it 'check any non-sequencing request is always ready' do
        assert_equal true, @library_creation_request.ready?
      end
    end

    context '#customer_responsible' do
      setup do
        @request = create :library_creation_request
        @request.state = 'started'
      end

      it 'update when request is started' do
        @request.request_metadata.update_attributes!(customer_accepts_responsibility: true)
        assert @request.request_metadata.customer_accepts_responsibility?
      end

      it 'not update once a request is failed' do
        @request.fail!
        expect { @request.request_metadata.update_attributes!(customer_accepts_responsibility: true) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    it 'should respond to #billing_product_identifier' do
      request = Request.new
      expect(request.billing_product_identifier).to be nil
    end
  end
end
