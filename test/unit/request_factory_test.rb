require "test_helper"

class RequestFactoryTest < ActiveSupport::TestCase
  context "RequestFactory" do
    context '.copy_request' do
      setup do
        @project = Factory(:project)
        @project.project_metadata.update_attributes!(:budget_division => BudgetDivision.create!(:name => 'Test'))
        @order = Factory(:order, :project => @project)
        @request = Factory(:request, :request_type => Factory(:request_type), :project => @project, :asset => Factory(:sample_tube), :target_asset => Factory(:well))
      end

      context 'without quotas' do
        setup do
          @project.update_attributes!(:enforce_quotas => false)
          @copy = RequestFactory.copy_request(@request)
        end

        should 'have the same request type' do
          assert_equal @request.request_type, @copy.request_type
        end

        should 'have no target asset' do
          assert_nil @copy.target_asset
        end

        should 'be pending' do
          assert_equal 'pending', @copy.state
        end
      end

      context 'with quotas' do
        setup do
          @project.update_attributes!(:enforce_quotas => true)
        end

        context 'when has enough quota' do
          setup do
            @project.quota_for!(@request.request_type).update_attributes!(:limit => 2, :preordered_count =>0)
            @request.reload
          end

          should 'not fail' do
            RequestFactory.copy_request(@request)
          end

          should 'fail if we request more than available' do
            RequestFactory.copy_request(@request)
            assert_raises(Quota::Error) { RequestFactory.copy_request(@request) }
          end
        end

        context 'when insufficient quota' do
          setup do
            @project.quota_for!(@request.request_type).update_attributes!(:limit => 1, :preordered_count =>0)
          end

          should 'raise an exception' do
            assert_raises(Quota::Error) { RequestFactory.copy_request(@request) }
          end
        end
      end
    end
  end

  context '.create_assets_requests' do
    setup do
      @study  = Factory(:study)
      @assets = [ Factory(:sample_tube), Factory(:sample_tube) ]

      RequestFactory.create_assets_requests(@assets.map(&:id), @study.id)
    end

    should 'have all create asset requests as passed' do
      assert_equal ['passed'], RequestType.find_by_key('create_asset').requests.map(&:state).uniq
    end

    should 'have the study on all requests' do
      assert_equal [@study.id], RequestType.find_by_key('create_asset').requests.map(&:study_id).uniq
    end

    should 'have the asset IDs' do
      assert_equal @assets.map(&:id).sort, RequestType.find_by_key('create_asset').requests.map(&:asset_id).sort
    end
  end
end
