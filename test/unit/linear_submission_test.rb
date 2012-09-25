require "test_helper"

class LinearSubmissionTest < ActiveSupport::TestCase
  context "LinearSubmission" do
    setup do
      @assets = (1..4).map { |i| Factory(:sample_tube, :name => "Asset#{ i }") } # NOTE: huh? why did this have ':id => 1'!?!!
      @asset_group = Factory :asset_group, :name => "non MPX", :assets => @assets

      @mpx_assets = (1..10).map { |i| Factory(:sample_tube, :name => "MX-asset#{ i }") }
      @mpx_asset_group = Factory :asset_group, :name => "MPX", :assets => @mpx_assets
      @workflow = Factory :submission_workflow
    end

    should_belong_to :study
    should_belong_to :user

    context "build (Submission factory)" do
      setup do
        @study = Factory :study
        @project = Factory :project
        @user = Factory :user

        @request_type_1 = Factory :request_type, :name => "request type 1"
        @library_creation_request_type = Factory :library_creation_request_type
        @sequencing_request_type = Factory :sequencing_request_type

        @request_type_ids = [@request_type_1.id, @library_creation_request_type.id, @sequencing_request_type.id]

        @request_options = {"read_length"=>"108", "fragment_size_required_from"=>"150", "fragment_size_required_to"=>"200"}
      end

      context 'multiplexed submission' do
        setup do
          @mpx_request_type = Factory :multiplexed_library_creation_request_type
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
              @mpx_submission.process!
            end

            should_not_change("Comment.count") { Comment.count }
            should_change("Request.count", :by => 11) { Request.count }
            should_change("Item.count", :by => 10) { Item.count }
          end

          context 'multiple requests' do
            setup do
              @sequencing_request_type_2 = Factory :sequencing_request_type
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

            should_not_change("Comment.count") { Comment.count }
            should_change("Request.count", :by => 12) { Request.count }
            should_change("Item.count", :by => 10) { Item.count }
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
            @submission.process!
          end

          should_change("Request.count", :by => 12) { Request.count }

          context "#create_requests_for_items" do
            setup do
              @submission.create_requests
            end

            should_change("Request.count", :by => 12) { Request.count }
            should_change("Comment.count", :by => 12) { Comment.count }

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


    context "#quota_check" do
      setup do
        @study = Factory :study
        @project = Factory :project
        @workflow = Factory :submission_workflow
        @user = Factory :user

        @request_type_1 = Factory :request_type, :name => "request type 1"
        @request_type_2 = Factory :library_creation_request_type, :name => "request type 2"
        @request_type_3 = Factory :sequencing_request_type
        @mpx_request_type = Factory :multiplexed_library_creation_request_type

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

        context "when quotas have been set up" do
          setup do
            @request_types.each do |request_type|
              @project.set_available_quotas!(request_type, @assets.length)
            end
            @project.set_available_quotas!(@mpx_request_type, @mpx_assets.length)
            @project.set_available_quotas!(@request_type_3, 1)
          end

          should 'allow the normal submission to build' do
            LinearSubmission.build!(@submission_params)
          end

          should 'allow the multiplexed submission to build' do
            LinearSubmission.build!(@mpx_submission_params)
          end
        end

        context "when quotas have been set to 0" do
          setup do
            @request_types.each do |request_type|
              @project.quota_for!(request_type).update_attributes!(:limit =>0, :preordered_count => 0)
            end
          end

          should 'not allow the normal submission to build' do
            assert_raises(Quota::Error) { LinearSubmission.build!(@submission_params) }
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

        context "when quotas have not been set up" do
          should 'not allow the normal submission to build' do
            assert_raises(Quota::Error) { LinearSubmission.build!(@submission_params) }
          end

          context 'when quotas are not being enforced' do
            setup do
              @project.update_attributes!(:enforce_quotas => false)
            end

            should 'allow the normal submission to build' do
              LinearSubmission.build!(@submission_params)
            end

            context 'then' do
              setup do
                @submission = LinearSubmission.build!(@submission_params)

              end
              should 'allow the submission to be processed' do
                @submission.process!
              end
              context 'when the quota have been enforced' do
                setup do
                @project.update_attributes!(:enforce_quotas => true)
                end
                should 'not allow the submission to be processed' do
                  assert_raises(Quota::Error) { @submission.process!}
                end
              end
            end
          end
        end
      end
    end

    context "process with a multiplier for request type" do
      setup do
        @study = Factory :study
        @project = Factory :project
        @workflow = Factory :submission_workflow

        @user = Factory :user

        @project = Factory :project
        @project.enforce_quotas = true

        @asset_1 = Factory(:sample_tube)
        @asset_2 = Factory(:sample_tube)

        @mx_request_type = Factory :request_type, :asset_type => "SampleTube", :target_asset_type=>"LibraryTube", :initial_state => "pending", :name => "Multiplexed Library Creation", :order => 1, :key => "multiplexed_library_creation"
        @lib_request_type = Factory :request_type, :asset_type => "SampleTube", :target_asset_type=>"LibraryTube", :initial_state => "pending", :name => "Library Creation", :order => 1, :key => "library_creation"
        @pe_request_type = Factory :request_type, :asset_type => "LibraryTube", :initial_state => "pending", :name => "PE sequencing", :order => 2, :key => "pe_sequencing"
        @se_request_type = Factory :request_type, :asset_type => "LibraryTube", :initial_state => "pending", :name => "SE sequencing", :order => 2, :key => "se_sequencing"

        Factory :project_quota, :project => @project, :limit => 20, :request_type => @mx_request_type
        Factory :project_quota, :project => @project, :limit => 60, :request_type => @lib_request_type
        Factory :project_quota, :project => @project, :limit => 60, :request_type => @pe_request_type
        Factory :project_quota, :project => @project, :limit => 0, :request_type => @se_request_type

        @submission_with_multiplication_factor = LinearSubmission.build!(
          :study            => @study,
          :project          => @project,
          :workflow         => @workflow,
          :user             => @user,
          :assets           => [ @asset_1, @asset_2 ],
          :request_types    => [ @lib_request_type.id, @pe_request_type.id ],
          :request_options  => { :multiplier => { @pe_request_type.id.to_s.to_sym => '5', @lib_request_type.id.to_s.to_sym => '1' } },
          :comments         => ''
        )
        @mx_submission_with_multiplication_factor = LinearSubmission.build!(
          :study            => @study,
          :project          => @project,
          :workflow         => @workflow,
          :user             => @user,
          :assets           => [ @asset_1, @asset_2 ],
          :request_types    => [ @mx_request_type.id, @pe_request_type.id ],
          :request_options  => { :multiplier => { @pe_request_type.id.to_s.to_sym => '5', @mx_request_type.id.to_s.to_sym => '1' } },
          :comments         => ''
        )
      end

      context "when a multiplication factor of 5 is provided" do
        context "when there's sufficient quota" do
          context "for non multiplexed libraries and sequencing" do
            setup do
              @submission_with_multiplication_factor.process!
            end
            should_change("Request.count", :by => 12) { Request.count }

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

          context "insufficient quota" do
            should "build will raise an exception" do
              $stop = true
              assert_raise Quota::Error do
                LinearSubmission.build!(
                  :study            => @study,
                  :project          => @project,
                  :workflow         => @workflow,
                  :user             => @user,
                  :assets           => [ @asset_1, @asset_2 ],
                  :request_types    => [ @lib_request_type.id, @se_request_type.id ],
                  :request_options  => { :multiplier => { @se_request_type.id.to_s.to_sym => '5', @lib_request_type.id.to_s.to_sym => '1' } },
                  :comments         => ''
                )
              end
            end
          end
        end
      end
    end
  end
end
