require 'test_helper'

class BatchMultiplexTest < ActiveSupport::TestCase

	attr_reader :batch_multiplex_label

	def setup
		pipeline = create :pipeline,
      :name          => 'Test pipeline',
      :workflow      => LabInterface::Workflow.create!(:item_limit => 8),
      :multiplexed => true
    batch = pipeline.batches.create!

    library_tube = create :library_tube, barcode: "111"

 		printable = {library_tube.id => "on"}
		options = {count: '1', printable: printable, batch: batch}
		@batch_multiplex_label = LabelPrinter::Label::BatchMultiplex.new(options)
	end

	test "should return correct tubes" do
		assert_equal 1, batch_multiplex_label.tubes.count
	end

end