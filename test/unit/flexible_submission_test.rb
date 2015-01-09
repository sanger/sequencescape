require "test_helper"

class FlexibleSubmissionTest < ActiveSupport::TestCase
  context "FlexibleSubmission" do
    setup do
      @assets       = Factory(:full_stock_plate).wells
      @workflow     = Factory :submission_workflow
      @pooling      = Factory :pooling_method
    end

    should_belong_to :study
    should_belong_to :user

    context "build (Submission factory)" do
      setup do
        @study    = Factory :study
        @project  = Factory :project
        @user     = Factory :user

        @library_creation_request_type = Factory :well_request_type, {:target_purpose => nil, :for_multiplexing=>true, :pooling_method=>@pooling}
        @sequencing_request_type = Factory :sequencing_request_type

        @request_type_ids = [@library_creation_request_type.id, @sequencing_request_type.id]

        @request_options = {"read_length"=>"108", "fragment_size_required_from"=>"150", "fragment_size_required_to"=>"200"}
      end

      context 'multiplexed submission' do
        setup do
          @mpx_submission = FlexibleSubmission.build!(
            :study            => @study,
            :project          => @project,
            :workflow         => @workflow,
            :user             => @user,
            :assets           => @assets,
            :request_types    => @request_type_ids,
            :request_options  => @request_options
          )
          @mpx_submission.save!
        end

        should 'be a multiplexed submission' do
          assert @mpx_submission.multiplexed?
        end

        context "#process!" do

          context 'multiple requests' do
            setup do
               @mpx_submission.process!
            end

            should_change("Request.count", :by => (96+8)) { Request.count }
          end
        end
      end

    end

    context "with target asset creation" do
      setup do
        @study    = Factory :study
        @project  = Factory :project
        @user     = Factory :user

        @library_creation_request_type = Factory :well_request_type, {:for_multiplexing=>true, :target_asset_type=>'MultiplexedLibraryTube', :pooling_method=>@pooling}
        @sequencing_request_type = Factory :sequencing_request_type

        @request_type_ids = [@library_creation_request_type.id, @sequencing_request_type.id]

        @request_options = {"read_length"=>"108", "fragment_size_required_from"=>"150", "fragment_size_required_to"=>"200"}
      end

      context 'multiplexed submission' do
        setup do

          @mpx_submission = FlexibleSubmission.build!(
            :study            => @study,
            :project          => @project,
            :workflow         => @workflow,
            :user             => @user,
            :assets           => @assets,
            :request_types    => @request_type_ids,
            :request_options  => @request_options
          )
        end

        should 'be a multiplexed submission' do
          assert @mpx_submission.multiplexed?
        end

        context "#process!" do

          context 'multiple requests' do
            setup do
               @mpx_submission.process!
            end

            should_change("Request.count", :by => (96+8)) { Request.count }

            should "set target assets according to the request_type.pool_by" do
              rows = (0...8).map
              used_assets = []

              @assets.group_by {|well| well.map.row }.each do |row,wells|
                assert rows.delete(row).present?, "Row #{row} was unexpected"
                unique_target_assets = wells.map {|w| w.requests.first.target_asset }.uniq
                assert_equal unique_target_assets.count, 1
                assert (used_assets&unique_target_assets).empty?, "Target assets are reused"
                used_assets.concat(unique_target_assets)
              end

              assert rows.empty?, "Didn't see rows #{rows.to_sentence}"
            end
          end
        end
      end

    end

    context "process with a multiplier for request type" do
      setup do

        @study = Factory :study
        @project = Factory :project
        @user = Factory :user

        @mx_request_type = Factory :well_request_type, {:target_purpose => nil, :for_multiplexing=>true, :pooling_method=>@pooling}
        @pe_request_type = Factory :request_type, :asset_type => "LibraryTube", :initial_state => "pending", :name => "PE sequencing", :order => 2, :key => "pe_sequencing"

        @request_type_ids = [ @mx_request_type.id, @pe_request_type.id ]

        @mx_submission_with_multiplication_factor = FlexibleSubmission.build!(
          :study            => @study,
          :project          => @project,
          :workflow         => @workflow,
          :user             => @user,
          :assets           => @assets,
          :request_types    => @request_type_ids,
          :request_options  => { :multiplier => { @pe_request_type.id.to_s.to_sym => '2', @mx_request_type.id.to_s.to_sym => '1' }, "read_length"=>"108", "fragment_size_required_from"=>"150", "fragment_size_required_to"=>"200" },
          :comments         => ''
        )
      end

      context "when a multiplication factor of 2 is provided" do

        context "for multiplexed libraries and sequencing" do
          setup do
            @mx_submission_with_multiplication_factor.process!
          end

          should "create 96 library requests and 40 sequencing requests" do
            lib_requests = Request.find_all_by_submission_id_and_request_type_id(@mx_submission_with_multiplication_factor, @mx_request_type.id)
            assert_equal 96, lib_requests.count
            seq_requests = Request.find_all_by_submission_id_and_request_type_id(@mx_submission_with_multiplication_factor, @pe_request_type.id)
            assert_equal 16, seq_requests.count
          end

        end

      end
    end
  end
end
