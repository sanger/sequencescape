
require 'test_helper'

class PulldownLibraryCreationPipelineTest < ActiveSupport::TestCase
  context 'Pipeline' do
    setup do
      @pipeline = build :pulldown_library_creation_pipeline
    end

    should 'be legacy' do
      assert_equal @pipeline.inbox_partial, 'deprecated_inbox'
    end
  end
end
