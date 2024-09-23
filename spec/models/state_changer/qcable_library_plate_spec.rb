# frozen_string_literal: true

# require 'rails_helper'
require 'spec_helper'

RSpec.describe StateChanger::QcableLibraryPlate do
  let(:state_changer) do
    described_class.new(labware:, target_state: 'passed', user:, contents:, customer_accepts_responsibility:)
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
    expect(well).to eq(aliquot.library)
    expect(aliquot.library_type).to eq('QA1')
    expect(aliquot.insert_size.from).to eq(100)
  end
end
