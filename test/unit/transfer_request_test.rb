require 'test_helper'

class TransferRequestTest < ActiveSupport::TestCase
  context 'TransferRequest' do
    context 'when starting the request' do
      setup do
        @source = SampleTube.create!(:sample => Factory(:sample))
        Factory(:tag).tag!(@source)

        @destination = LibraryTube.create!

        TransferRequest.create!(:asset => @source, :target_asset => @destination).start!
      end

      context 'the tags' do
        should 'be assigned the same tags' do
          assert_equal(@source.parents.map(&:tag), @destination.parents.map(&:tag))
        end

        should 'be different tag instances' do
          assert_not_equal(@source.parents, @destination.parents)
        end
      end

      should 'link the sample to the target asset' do
        assert_equal(@source.sample, @destination.sample)
      end
    end
  end
end
