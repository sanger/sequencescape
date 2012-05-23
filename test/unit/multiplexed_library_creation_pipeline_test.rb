require 'test_helper'

class MultiplexedLibraryCreationPipelineTest < ActiveSupport::TestCase
  def setup
    @pipeline = Pipeline.find_by_name('Illumina-B MX Library Preparation') or raise StandardError, "Cannot find the Illumina-B MX Library Preparation pipeline"
    @user     = Factory(:user)
  end

  context 'batch interaction' do
    setup do
      @batch = Factory(:batch, :pipeline => @pipeline)
      @batch.requests << (1..5).map { |_| Factory(:request_suitable_for_starting, :request_type => @batch.pipeline.request_types.last) }
    end

    context 'for completion' do
      setup do
        @batch.start!(@user)
      end

      should 'add errors if there are untagged target asset aliquots' do
        @batch.requests.map(&:target_asset).map(&:untag!)

        assert_raise(ActiveRecord::RecordInvalid) do
          @batch.complete!(@user)
        end

        assert(!@batch.errors.empty?, "There are no errors on the batch")
      end

      should 'not error if all of the target asset aliquots are tagged' do
        @batch.requests.each_with_index { |r,i| Factory(:tag, :map_id => i).tag!(r.target_asset) }
        @batch.complete!(@user)

        assert(@batch.errors.empty?, "There are errors on the batch")
      end
    end
  end
end
