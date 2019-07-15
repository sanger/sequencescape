require 'test_helper'

class MultiplexedLibraryCreationPipelineTest < ActiveSupport::TestCase
  def setup
    @pipeline = create :multiplexed_library_creation_pipeline
    @user     = create(:user)
  end

  context 'batch interaction' do
    setup do
      @batch = create(:batch, pipeline: @pipeline)
      @batch.requests = create_list(:multiplexed_library_creation_request, 5, request_type: @batch.pipeline.request_types.last)
    end

    context 'for completion' do
      setup do
        @batch.start!(@user)
        # The loaded target_assets are still empty, as the code updates them through an eager
        # loaded scope. Complete! is only called on a freshly loaded batch in a separate
        # web request, so this is merely a side effect of the way the tests are written.
        @batch.reload
      end

      should 'add errors if there are untagged target asset aliquots' do
        @batch.requests.map(&:target_asset).map(&:untag!)

        assert_raise(ActiveRecord::RecordInvalid) do
          @batch.complete!(@user)
        end

        assert(!@batch.errors.empty?, 'There are no errors on the batch')
      end

      should 'not error if all of the target asset aliquots are tagged' do
        @batch.requests.each_with_index { |r, i| create(:tag, map_id: i).tag!(r.target_asset) }
        @batch.complete!(@user)

        assert(@batch.errors.empty?, 'There are errors on the batch')
      end
    end
  end
end
