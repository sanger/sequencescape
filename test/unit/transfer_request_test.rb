require 'test_helper'

class TransferRequestTest < ActiveSupport::TestCase
  context 'TransferRequest' do
    context 'when starting the request' do
      setup do
        @source = LibraryTube.create!.tap { |tube| tube.aliquots.create!(:sample => Factory(:sample)) }
        Factory(:tag).tag!(@source)

        @destination = LibraryTube.create!

        TransferRequest.create!(:asset => @source, :target_asset => @destination)
      end

      should 'duplicate the aliquots' do
        expected_aliquots = @source.aliquots.map { |a| [ a.sample_id, a.tag_id ] }
        target_aliquots   = @destination.aliquots.map { |a| [ a.sample_id, a.tag_id ] }
        assert_equal(expected_aliquots, target_aliquots)
      end
    end
  end
end
