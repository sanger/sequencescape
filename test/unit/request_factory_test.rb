require "test_helper"

class RequestFactoryTest < ActiveSupport::TestCase
  context "RequestFactory" do
    setup do
      @asset = Factory :asset, :sti_type => "SampleTube"
      @asset.sample = Factory :sample

      @request_type = Factory :sequencing_request_type, :asset_type => "SampleTube", :initial_state => "pending"
      @bad_request_type = Factory :request_type

      @asset.stubs(:label).returns(@request_type.asset_type)

      @request_metadata_hash = {:fragment_size_required_to => 1,
        :fragment_size_required_from => 999,
        :library_type => 'Standard',
        :read_length => 108}
      @submission = Factory :submission, :request_options => {"pdk1" => "a", "pdk2" => "b"}.merge(@request_metadata_hash)

      @item = Factory :item, :name => "#{@asset.name} #{@submission.id}"

      @project = @submission.project
      @project.enforce_quotas = true
    end

    should "have same asset_type" do
      assert_equal @asset.sti_type, @request_type.asset_type
    end

    context "Create a single Request with sufficient Quota" do
      setup do
        @quota = Factory :project_quota, :project_id => @project.id, :request_type_id => @request_type.id, :limit => 10
        @request_factory = RequestFactory.new(@submission)
        @request = @request_factory.create_request(@request_type, @item, @asset)
      end

      should_change("Request.count", :by => 1) { Request.count }
      should_change("@asset.requests.count", :by => 1) { @asset.requests.count }

      should "add Requests to Asset" do        
        assert_equal @request.asset, @asset
      end

      should "have submission, item and asset" do
        assert_not_nil @request.item
        assert_not_nil @request.asset
        assert_not_nil @request.submission
      end

      should "set Request state equal to RequestType initial state" do
        assert_equal @request.state, @request_type.initial_state
      end

      context 'request' do
        subject { @request.request_metadata }
        should_default_everything(Request::Metadata)
      end

      context "Copy a single Request with sufficient Quota" do
        setup do
          @request_copy = RequestFactory.copy_request(@request)
        end

        should "have the same metadata" do
          request_properties = @request.request_metadata.attributes.merge('id' => nil, 'request_id' => nil)
          copy_properties    = @request_copy.request_metadata.attributes.merge('id' => nil, 'request_id' => nil)
          assert_equal request_properties, copy_properties
        end

        should "have submission, item and asset" do
          assert_not_nil @request_copy.item
          assert_not_nil @request_copy.asset
          assert_not_nil @request_copy.submission
        end

        should "have (some of) the same associations" do
          # TODO - some of these associations should be obtained transitively:
          assert_equal @request.submission, @request_copy.submission
          assert_equal @request.item, @request_copy.item
          assert_equal @request.asset.name, @request_copy.asset.name # Due to STI
          assert_equal @request.asset.id, @request_copy.asset.id
          assert_equal @request.project, @request_copy.project
          assert_equal @request.workflow, @request_copy.workflow
          assert_equal @request.sample, @request_copy.sample
          assert_equal @request.user, @request_copy.user
          assert_equal @request.request_type, @request_copy.request_type
        end

        should "not have (some of) the same associations" do
          assert_equal @request_copy.target_asset, nil
        end

        should "Item should be named sample + submission.id" do
          assert_equal "#{@request_copy.asset.name} #{@request_copy.submission_id}", @request_copy.item.name
        end

        should "be pending" do
          assert @request_copy.pending?
        end

        should "have been created at a later time than the original" do
          assert @request.created_at < @request_copy.created_at
        end
      end

      context "Attempt to copy a single Request with insufficient Quota" do
        setup do
          # Remove other quotas
          @project.quotas = []
          Factory :project_quota, :project_id => @project.id, :request_type_id => @request_type.id, :limit => 0
          @request.submission.project = @project
        end

        should "raise a Quota exception" do
          assert_raise(QuotaException) {
            RequestFactory.copy_request(@request)
          }
        end
      end
    end

    context "Create multiplexed Request with sufficient Quota" do
      setup do
        quota = Factory :project_quota, :project_id => @project.id, :request_type_id => @request_type.id, :limit => 10
        study = Factory :study
        user  = Factory :user
        workflow = Factory :submission_workflow
        request_type_ids = [@request_type.id]
        properties = @request_metadata_hash
        multiplier = 1
        assets = [@asset]
        (@submission, @requests) = RequestFactory.create_requests(study, @project, workflow, user, assets, request_type_ids, properties, multiplier)
      end

      should_change("Request.count", :by => 1) { Request.count }
      should_change("@asset.requests.count", :by => 1) { @asset.requests.count } 

      should 'have a submission' do
        assert_not_nil @submission
      end

      context 'request' do
        setup do
          @request = @requests.first
        end

        should 'have an item' do
          assert_not_nil @request.item
        end

        should 'have an asset' do
          assert_not_nil @request.item
        end

        should 'have an association' do
          assert_not_nil @request.submission
        end

        should "set the read length correctly" do
          assert_equal 108, @request.request_metadata.read_length
        end

        should "Item should be named sample + submission.id" do
          assert_equal "#{@request.asset.name} #{@request.submission_id}", @request.item.name
        end
      end
    end
  end

  context "request with a well" do
    setup do
      source_well = Factory :well
      request_type = RequestType.find_by_key("cherrypick")
      @target_well = RequestFactory.create_target_asset(source_well, request_type)
    end
    should "create a well attribute" do
      assert_not_nil @target_well.well_attribute
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
