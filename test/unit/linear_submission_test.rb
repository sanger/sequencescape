#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014 Genome Research Ltd.
require "test_helper"

class LinearSubmissionTest < ActiveSupport::TestCase
  context "LinearSubmission" do
    setup do
      @assets = (1..4).map { |i| create(:sample_tube, :name => "Asset#{ i }") } # NOTE: huh? why did this have ':id => 1'!?!!
      @asset_group = create :asset_group, :name => "non MPX", :assets => @assets

      @mpx_assets = (1..10).map { |i| create(:sample_tube, :name => "MX-asset#{ i }") }
      @mpx_asset_group = create :asset_group, :name => "MPX", :assets => @mpx_assets
      @workflow = create :submission_workflow
    end

    should belong_to :study
    should belong_to :user

    context "build (Submission factory)" do
      setup do
        @study = create :study
        @project = create :project
        @user = create :user

        @request_type_1 = create :request_type, :name => "request type 1"
        @library_creation_request_type = create :library_creation_request_type
        @sequencing_request_type = create :sequencing_request_type

        @purpose = create :plate_purpose, :name => "mock purpose", :type=>'Tube::StandardMx', :target_type => 'MultiplexedLibraryTube'

        @request_type_ids = [@request_type_1.id, @library_creation_request_type.id, @sequencing_request_type.id]

        @request_options = {"read_length"=>"108", "fragment_size_required_from"=>"150", "fragment_size_required_to"=>"200"}
      end

      context 'multiplexed submission' do
        setup do
          @mpx_request_type = create :multiplexed_library_creation_request_type, {:target_purpose => @purpose}
          @mpx_request_type_ids = [@mpx_request_type.id, @sequencing_request_type.id]

          @mpx_submission = LinearSubmission.build!(
            :study            => @study,
            :project          => @project,
            :workflow         => @workflow,
            :user             => @user,
            :assets           => @mpx_assets,
            :request_types    => @mpx_request_type_ids,
            :request_options  => @request_options
          )
          @mpx_submission.save!
        end

        should 'be a multiplexed submission' do
          assert @mpx_submission.multiplexed?
        end

        should "not save a comment if one isn't supplied" do
          assert @mpx_submission.comments.blank?
        end

        context "#process!" do
          context 'single request' do
            setup do
              @initial_comment_count = Comment.count
              @request_count =  Request.count
              @item_count =  Item.count
              @mpx_submission.process!
            end

            should "not change Comment.count" do
              assert_equal @initial_comment_count, Comment.count
            end

 should "change Request.count by 11" do
   assert_equal 11,  Request.count  - @request_count, "Expected Request.count to change by 11"
end

 should "change Item.count by 10" do
   assert_equal 10,  Item.count  - @item_count, "Expected Item.count to change by 10"
end
          end

          context 'multiple requests' do
            setup do
              @initial_comment_count = Comment.count
              @request_count =  Request.count
              @item_count =  Item.count
              @sequencing_request_type_2 = create :sequencing_request_type
              @mpx_request_type_ids = [@mpx_request_type.id, @sequencing_request_type_2.id, @sequencing_request_type.id]

              @multiple_mpx_submission = LinearSubmission.build!(
                :study            => @study,
                :project          => @project,
                :workflow         => @workflow,
                :user             => @user,
                :assets           => @mpx_assets,
                :request_types    => @mpx_request_type_ids,
                :request_options  => @request_options
              )

              @multiple_mpx_submission.process!
            end

            should "not change Comment.count" do
              assert_equal @initial_comment_count, Comment.count
            end

 should "change Request.count by 12" do
   assert_equal 12,  Request.count  - @request_count, "Expected Request.count to change by 12"
end

 should "change Item.count by 10" do
   assert_equal 10,  Item.count  - @item_count, "Expected Item.count to change by 10"
end
          end
        end
      end

      context 'normal submission' do
        setup do
          @submission = LinearSubmission.build!(
            :study            => @study,
            :project          => @project,
            :workflow         => @workflow,
            :user             => @user,
            :assets           => @assets,
            :request_types    => @request_type_ids,
            :request_options  => @request_options,
            :comments         => 'This is a comment'
          )
          @submission.save!
        end

        should 'not be a multiplexed submission' do
          assert !@submission.multiplexed?
        end

        should "save request_types as array of Fixnums" do
          assert_kind_of Array, @submission.orders.first.request_types
          assert @submission.orders.first.request_types.all? {|sample| sample.kind_of?(Fixnum) }
        end

        should "save a comment if there's one passed in" do
          assert_equal ["This is a comment"], @submission.comments
        end

        context '#process!' do
          setup do
            @request_count =  Request.count
            @submission.process!
          end

         should "change Request.count by 12" do
           assert_equal 12,  Request.count  - @request_count, "Expected Request.count to change by 12"
        end

          context "#create_requests_for_items" do
            setup do
              @request_count =  Request.count
              @comment_count =  Comment.count
              @submission.create_requests
            end

           should "change Request.count by 12" do
             assert_equal 12,  Request.count  - @request_count, "Expected Request.count to change by 12"
          end

           should "change Comment.count by 12" do
             assert_equal 12,  Comment.count  - @comment_count, "Expected Comment.count to change by 12"
          end

            should "assign submission ids to the requests" do
              assert_equal @submission, @submission.items.first.requests.first.submission
            end

            context 'request type 1' do
              setup do
                @request_to_check = @submission.items.first.requests.first(:conditions => { :request_type_id => @request_type_1.id })
              end

              subject { @request_to_check.request_metadata }
              should_default_everything(Request::Metadata)
            end

            context 'library creation request type' do
              setup do
                @request_to_check = @submission.items.first.requests.first(:conditions => { :request_type_id => @library_creation_request_type.id })
              end

              subject { @request_to_check.request_metadata }
              should_default_everything_but(Request::Metadata, :fragment_size_required_to, :fragment_size_required_from)

              should 'assign fragment_size_required_to' do
                assert_equal '200', subject.fragment_size_required_to
              end

              should 'assign fragment_size_required_from' do
                assert_equal '150', subject.fragment_size_required_from
              end
            end

            context 'sequencing request type' do
              setup do
                @request_to_check = @submission.items.first.requests.first(:conditions => { :request_type_id => @sequencing_request_type.id })
              end

              subject { @request_to_check.request_metadata }
              should_default_everything_but(Request::Metadata, :read_length)

              should 'assign read_length' do
                assert_equal 108, subject.read_length
              end
            end
          end
        end
      end
    end


    context "#no quota_check" do
      setup do
        @study = create :study
        @project = create :project
        @workflow = create :submission_workflow
        @user = create :user

        @request_type_1 = create :request_type, :name => "request type 1"
        @request_type_2 = create :library_creation_request_type, :name => "request type 2"
        @request_type_3 = create :sequencing_request_type
        @mpx_request_type = create :multiplexed_library_creation_request_type

        @request_type_ids = [@request_type_1.id, @request_type_2.id]
        @mpx_request_type_ids = [@mpx_request_type.id, @request_type_3.id]

        @request_types = [@request_type_1, @request_type_2]

        @request_options = {"read_length"=>"108", "fragment_size_required_from"=>"150", "fragment_size_required_to"=>"200"}

        @submission_params = {
          :study            => @study,
          :project          => @project,
          :workflow         => @workflow,
          :user             => @user,
          :assets           => @assets,
          :request_types    => @request_type_ids,
          :request_options  => @request_options,
          :comments         => 'This is a comment'
        }
        @mpx_submission_params = {
          :study            => @study,
          :project          => @project,
          :workflow         => @workflow,
          :user             => @user,
          :assets           => @mpx_assets,
          :request_types    => @mpx_request_type_ids,
          :request_options  => @request_options
        }
      end

      context "when quotas are being enforced" do
        setup do
          @project.update_attributes(:enforce_quotas => true)
        end

        should 'allow the normal submission to build' do
          LinearSubmission.build!(@submission_params)
        end

        should 'allow the multiplexed submission to build' do
          LinearSubmission.build!(@mpx_submission_params)
        end
      end

      context 'when quotas are not being enforced' do
        setup do
          @project.update_attributes!(:enforce_quotas => false)
        end

        should 'allow the normal submission to build' do
          LinearSubmission.build!(@submission_params)
        end
      end

    end

    context "process with a multiplier for request type" do
      setup do
        @study = create :study
        @project = create :project
        @workflow = create :submission_workflow

        @user = create :user

        @project = create :project
        @project.enforce_quotas = true

        @asset_1 = create(:sample_tube)
        @asset_2 = create(:sample_tube)

        @mx_request_type = create :multiplexed_library_creation_request_type, :asset_type => "SampleTube", :target_asset_type=>"LibraryTube", :initial_state => "pending", :name => "Multiplexed Library Creation", :order => 1, :key => "multiplexed_library_creation"
        @lib_request_type = create :library_creation_request_type, :asset_type => "SampleTube", :target_asset_type=>"LibraryTube", :initial_state => "pending", :name => "Library Creation", :order => 1, :key => "library_creation"
        @pe_request_type = create :request_type, :asset_type => "LibraryTube", :initial_state => "pending", :name => "PE sequencing", :order => 2, :key => "pe_sequencing"
        @se_request_type = create :request_type, :asset_type => "LibraryTube", :initial_state => "pending", :name => "SE sequencing", :order => 2, :key => "se_sequencing"

        @submission_with_multiplication_factor = LinearSubmission.build!(
          :study            => @study,
          :project          => @project,
          :workflow         => @workflow,
          :user             => @user,
          :assets           => [ @asset_1, @asset_2 ],
          :request_types    => [ @lib_request_type.id, @pe_request_type.id ],
          :request_options  => { :multiplier => { @pe_request_type.id.to_s.to_sym => '5', @lib_request_type.id.to_s.to_sym => '1' }, "read_length"=>"108", "fragment_size_required_from"=>"150", "fragment_size_required_to"=>"200" },
          :comments         => ''
        )
        @mx_submission_with_multiplication_factor = LinearSubmission.build!(
          :study            => @study,
          :project          => @project,
          :workflow         => @workflow,
          :user             => @user,
          :assets           => [ @asset_1, @asset_2 ],
          :request_types    => [ @mx_request_type.id, @pe_request_type.id ],
          :request_options  => { :multiplier => { @pe_request_type.id.to_s.to_sym => '5', @mx_request_type.id.to_s.to_sym => '1' }, "read_length"=>"108", "fragment_size_required_from"=>"150", "fragment_size_required_to"=>"200" },
          :comments         => ''
        )
      end

      context "when a multiplication factor of 5 is provided" do

        context "for non multiplexed libraries and sequencing" do
          setup do
            @request_count =  Request.count
            @submission_with_multiplication_factor.process!
          end

           should "change Request.count by 12" do
             assert_equal 12,  Request.count  - @request_count, "Expected Request.count to change by 12"
          end

          should "create 2 library requests" do
            lib_requests = Request.find_all_by_submission_id_and_request_type_id(@submission_with_multiplication_factor, @lib_request_type.id)
            assert_equal 2, lib_requests.size
          end

          should "create 10 sequencing requests" do
            seq_requests = Request.find_all_by_submission_id_and_request_type_id(@submission_with_multiplication_factor, @pe_request_type.id)
            assert_equal 10, seq_requests.size
          end
        end

        context "for non multiplexed libraries and sequencing" do
          setup do
            @mx_submission_with_multiplication_factor.process!
          end
        end

      end
    end
  end
end
