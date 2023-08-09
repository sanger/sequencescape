# frozen_string_literal: true

# require 'rails_helper'
require 'spec_helper'

RSpec.describe StateChanger::QcableLibraryPlate do
  let(:state_changer) do
    described_class.new(
      labware: labware,
      target_state: 'passed',
      user: user,
      contents: contents,
      customer_accepts_responsibility: customer_accepts_responsibility
    )
  end
  let(:labware) { instance_double('Plate', wells: [well]) } # rubocop:todo RSpec/VerifiedDoubleReference
  let(:well) { instance_double('Well', aliquots: [aliquot]) } # rubocop:todo RSpec/VerifiedDoubleReference
  let(:user) { build_stubbed :user }
  let(:contents) { [] }
  let(:customer_accepts_responsibility) { false }
  let(:aliquot) do
    Struct
      .new(:library, :library_type, :insert_size) do
        def save!
          true
        end
      end
      .new
  end

  it 'sets library type on aliquots' do
    state_changer.update_labware_state
    assert_equal aliquot.library, well
    assert_equal aliquot.library_type, 'QA1'
    assert_equal aliquot.insert_size.from, 100
  end
end
