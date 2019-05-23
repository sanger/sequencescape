require 'test_helper'
require 'submissions_controller'

class SplitSubmissionBatchesTest < ActionController::TestCase
  context 'when I have a submission' do
    setup do
      @user = FactoryBot.create :user
      @controller = SubmissionsController.new
      @request    = ActionController::TestRequest.create(@controller)
      @plate_purpose = create :stock_plate_purpose
      @controller.stubs(:logged_in?).returns(@user)
      session[:user] = @user.id
      @project = FactoryBot.create :project
      @study = FactoryBot.create :study
      @asset_count = 4
      @asset_group = FactoryBot.create :asset_group
      @asset_group.assets = create_list :sample_tube, @asset_count
      @sequencing_pipeline = create :sequencing_pipeline
    end

    context 'which is single plexed' do
      setup do
        @lc = create :library_creation_request_type, target_asset_type: nil
        seq = create :sequencing_request_type
        # We're using the submissions controller as things are a bit screwy if we go to the plate creator (PlateCreater) directly
        # However, as this seems to relate to the multiplier, it may be related to out problem.
        submission_template_hash = { name: 'Singleplexed-template',
                                     submission_class_name: 'LinearSubmission',
                                     product_catalogue: 'Generic',
                                     submission_parameters: { info_differential: 5,
                                                              request_types: [@lc.key, seq.key] } }

        @submission_template = SubmissionSerializer.construct!(submission_template_hash)

        post(:create, params: {
               submission: {
                 is_a_sequencing_order: 'true',
                 comments: '',
                 template_id: @submission_template.id,
                 order_params: {
                   'read_length' => '37',
                   'fragment_size_required_to' => '400',
                   'fragment_size_required_from' => '100',
                   'library_type' => @lc.library_types.first.name
                 },
                 asset_group_id: @asset_group.id,
                 study_id: @study.id,
                 sample_names_text: '',
                 plate_purpose_id: @plate_purpose.id,
                 project_name: @project.name,
                 lanes_of_sequencing_required: '5',
                 priority: 1
               }
             })

        Submission.last.built!
        Submission.last.build_batch
      end

      # This is all a bit convoluted, and depends of some very specific options.
      context 'and I batch up the library creation requests seperately' do
        setup do
          @requests_group_a = LibraryCreationRequest.all[0..1]
          @requests_group_b = LibraryCreationRequest.all[2..3]
          @pipeline = create :library_creation_pipeline, request_types: [@lc], asset_type: 'LibraryTube'
          @batch_a = Batch.create!(requests: @requests_group_a, pipeline: @pipeline)
          @batch_a.start!(user: @user)
          @batch_a.complete!(@user)
          @batch_a.release!(@user)
        end

        should 'before failing any sequencing requests' do
          assert_equal LibraryCreationRequest.first.id + @asset_count, LibraryCreationRequest.first.next_requests.first.id
          assert_equal LibraryCreationRequest.all[2].id + 12, LibraryCreationRequest.all[2].next_requests.first.id
        end
      end
    end

    context 'which is multiplexed' do
      setup do
        lc = create :multiplexed_library_creation_request_type
        seq = create :sequencing_request_type
        # We're using the submissions controller as things are a bit screwy if we go to the plate creator (PlateCreater) directly
        # However, as this seems to relate to the multiplier, it may be related to out problem.
        # @asset_group.assets.each_with_index {|a,i| tag=FactoryBot.create :tag; a.aliquots.first.update!(:tag=>tag)}
        submission_template_hash = { name: 'Multiplexed-template',
                                     submission_class_name: 'LinearSubmission',
                                     product_catalogue: 'Generic',
                                     submission_parameters: { info_differential: 5,
                                                              request_types: [lc.key, seq.key] } }

        @submission_template = SubmissionSerializer.construct!(submission_template_hash)

        post(:create, params: { submission: {
               is_a_sequencing_order: 'true',
               comments: '',
               template_id: @submission_template.id.to_s,
               order_params: {
                 'read_length' => '37', 'fragment_size_required_to' => '400', 'bait_library_name' => 'Human all exon 50MB',
                 'fragment_size_required_from' => '100', 'library_type' => 'Standard'
               },
               asset_group_id: @asset_group.id.to_s,
               study_id: @study.id.to_s,
               sample_names_text: '',
               plate_purpose_id: @plate_purpose.id.to_s,
               project_name: @project.name,
               lanes_of_sequencing_required: '5',
               priority: 1
             } })

        Submission.last.built!
        Delayed::Worker.new.work_off
      end

      should 'report correct groupings from the start' do
        assert_equal MultiplexedLibraryCreationRequest.first.id + 4, MultiplexedLibraryCreationRequest.first.next_requests.first.id
        assert_equal MultiplexedLibraryCreationRequest.first.id + 4, MultiplexedLibraryCreationRequest.all[2].next_requests.first.id
        assert_equal 5, MultiplexedLibraryCreationRequest.first.next_requests.size
        assert_equal MultiplexedLibraryCreationRequest.first.id + 8, MultiplexedLibraryCreationRequest.first.next_requests.last.id
      end
    end
  end
end
