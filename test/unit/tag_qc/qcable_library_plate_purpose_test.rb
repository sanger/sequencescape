require "test_helper"

class QcableLibraryPlatePurposeTest < ActiveSupport::TestCase

  class MockAliquot
    attr_accessor :library, :library_type, :insert_size
    def save!;true;end
  end

  context "A Qcable Library Plate Purpose" do

    context "#QcableLibraryPlatePurpose" do
      should 'set library type on aliquots' do

        @purpose = QcableLibraryPlatePurpose.new(:name=>'test_purpose')

        plate = mock('plate')
        well  = mock('well')
        aliquot = MockAliquot.new
        plate.expects(:wells).returns([well])
        well.expects(:aliquots).returns([aliquot])

        @purpose.transition_to(plate, 'passed')

        assert_equal aliquot.library, well
        assert_equal aliquot.library_type, 'QA1'
        assert_equal aliquot.insert_size, 100

      end
    end
  end

end
