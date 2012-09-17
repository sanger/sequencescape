require "test_helper"
require 'submissions_controller'

class WorkflowsController
  attr_accessor :batch, :tags, :workflow, :stage
end

class SplitSubmissionBatchesTest < ActionController::TestCase

  context "when I have a submission" do

    setup do
      @user = Factory :user
      @controller = SubmissionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @plate_purpose = PlatePurpose.find_by_name('Stock plate')
      @controller.stubs(:logged_in?).returns(@user)
      @controller.stubs(:current_user).returns(@user)
      @project = Factory :project
      @study = Factory :study
      @asset1 = Factory :sample_tube
      @asset2 = Factory :sample_tube
      @asset3 = Factory :sample_tube
      @asset4 = Factory :sample_tube
      @asset_group = Factory :asset_group
      @asset_group.assets << @asset1 << @asset2 << @asset3 << @asset4
      @sequencing_pipeline = Pipeline.find_by_name('Cluster formation SE')
    end

    context "which is single plexed" do
      setup do
        # We're using the submissions controller as things are a bit screwy if we go to the plate creator (PlateCreater) directly
        # However, as this seems to relate to the multiplier, it may be related to out problem.
        @submission_template = SubmissionTemplate.find_by_name('Library creation - Single ended sequencing')

        post(:create, :submission => {:is_a_sequencing_order=>"true", :comments=>"", :template_id=>@submission_template.id, :order_params=>{"read_length"=>"37", "fragment_size_required_to"=>"400", "bait_library_name"=>"Human all exon 50MB", "fragment_size_required_from"=>"100", "library_type"=>"Agilent Pulldown"}, :asset_group_id=>@asset_group.id, :study_id=>@study.id, :sample_names_text=>"", :plate_purpose_id=>@plate_purpose.id, :project_name=>@project.name, :lanes_of_sequencing_required=>"5"})

        Submission.last.built!
        Delayed::Worker.new.work_off(1)
      end

      context "and I batch up the library creation requests seperately" do

        setup do
          @requests_group_a = LibraryCreationRequest.all[0..1]
          @requests_group_b = LibraryCreationRequest.all[2..3]
          @pipeline = LibraryCreationRequest.first.request_type.pipelines.first
          @batch_a = Batch.create!(:requests=>@requests_group_a, :pipeline=>@pipeline)
          @batch_a.start!(:user=>@user)
          @batch_a.complete!(@user)
          @batch_a.release!(@user)

        end

        should "before failing any sequencing requests" do
          assert_equal LibraryCreationRequest.first.id+4, LibraryCreationRequest.first.next_requests(@pipeline) {|r| true}.first.id
          assert_equal LibraryCreationRequest.all[2].id+12, LibraryCreationRequest.all[2].next_requests(@pipeline) {|r| true}.first.id
        end

        context "afer failing sequencing requests" do
          setup do

            @sequencing_group = SequencingRequest.all[0..1]
            @seq_batch = Batch.create!(:requests=>@sequencing_group, :pipeline=>@sequencing_pipeline)

            @seq_batch.requests.map(&:start!)
            @seq_batch.fail('just','because')
            @seq_batch.requests.each {|r| @seq_batch.detach_request(r)}
          end

          should "correctly identify the next requests" do
            assert_equal LibraryCreationRequest.first.id+4, LibraryCreationRequest.first.next_requests(@pipeline) {|r| true}.first.id
            assert_equal LibraryCreationRequest.all[2].id+12, LibraryCreationRequest.all[2].next_requests(@pipeline) {|r| true}.first.id
          end

        end

      end

    end


    context "which is multiplexed" do
         setup do
           # We're using the submissions controller as things are a bit screwy if we go to the plate creator (PlateCreater) directly
           # However, as this seems to relate to the multiplier, it may be related to out problem.
           #@asset_group.assets.each_with_index {|a,i| tag= Factory :tag; a.aliquots.first.update_attributes!(:tag=>tag)}
           @submission_template = SubmissionTemplate.find_by_name('Illumina-B Multiplexed Library Creation - Single ended sequencing')
           @library_pipeline = Pipeline.find_by_name('Illumina-B MX Library Preparation')

           post(:create, :submission => {
             :is_a_sequencing_order  => "true",
             :comments               => "",
             :template_id            => @submission_template.id.to_s,
             :order_params           => {
               "read_length"=>"37", "fragment_size_required_to"=>"400", "bait_library_name"=>"Human all exon 50MB",
               "fragment_size_required_from"=>"100", "library_type"=>"Agilent Pulldown"
               },
             :asset_group_id         => @asset_group.id.to_s,
             :study_id               => @study.id.to_s,
             :sample_names_text      => "",
             :plate_purpose_id       => @plate_purpose.id.to_s,
             :project_name           => @project.name,
             :lanes_of_sequencing_required=>"5"
             })

           Submission.last.built!
           Delayed::Worker.new.work_off(1)
         end

         should "report correct groupings from the start" do
           assert_equal MultiplexedLibraryCreationRequest.first.id+4, MultiplexedLibraryCreationRequest.first.next_requests(@library_pipeline) {|r| true}.first.id
           assert_equal MultiplexedLibraryCreationRequest.first.id+4, MultiplexedLibraryCreationRequest.all[2].next_requests(@library_pipeline) {|r| true}.first.id
           assert_equal 5, MultiplexedLibraryCreationRequest.first.next_requests(@library_pipeline) {|r| true}.size
           assert_equal MultiplexedLibraryCreationRequest.first.id+8, MultiplexedLibraryCreationRequest.first.next_requests(@library_pipeline) {|r| true}.last.id
         end

         # context "and I batch the requests" do
         #
         #            setup do
         #              @batch_a = Batch.create!(:requests=>MultiplexedLibraryCreationRequest.all, :pipeline=>@library_pipeline)
         #              @batch_a.start!(:user=>@user)
         #
         #              @task      = Factory :assign_tags_task
         #              @tag_group = Factory :tag_group
         #              @workflow = Factory :lab_workflow_for_pipeline
         #
         #              @tag_hash = {}
         #
         #              @wf_controller  = WorkflowsController.new
         #              $stop = true
         #              @wf_controller.batch = @batch_a
         #
         #              MultiplexedLibraryCreationRequest.all.each do |r|
         #               tag = Factory :tag, :tag_group => @tag_group
         #               @tag_hash[r.id.to_s] = tag.id.to_s
         #              end
         #
         #              params = { :workflow_id => @workflow, :batch_id => @batch_a.id,
         #                         :tag_group => @tag_group.id.to_s,
         #                         :mx_library_name => "MX library",
         #                         :tag => @tag_hash,
         #                          }
         #              @task.do_task(@wf_controller, params)
         #
         #              @batch_a.complete!(@user)
         #              @batch_a.release!(@user)
         #            end
         #
         #            should "before failing any sequencing requests" do
         #              assert_equal MultiplexedLibraryCreationRequest.first.id+4, MultiplexedLibraryCreationRequest.first.next_requests(@library_pipeline) {|r| true}.first.id
         #            end
         #
         #            context "afer failing sequencing requests" do
         #              setup do
         #                @sequencing_group = SequencingRequest.all
         #                @seq_batch = Batch.create!(:requests=>@sequencing_group, :pipeline=>@sequencing_pipeline)
         #                @seq_batch.requests.map(&:start!)
         #                @seq_batch.fail('just','because')
         #                @seq_batch.requests.each {|r| @seq_batch.detach_request(r)}
         #              end
         #
         #              should "correctly identify the next requests" do
         #                assert_equal MultiplexedLibraryCreationRequest.first.id+4, MultiplexedLibraryCreationRequest.first.next_requests(@library_pipeline) {|r| true}.first.id
         #              end
         #
         #            end
         #
         #          end

    end
  end
end



