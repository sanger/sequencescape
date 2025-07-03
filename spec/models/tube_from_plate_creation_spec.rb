# frozen_string_literal: true

# spec/models/tube_from_plate_creation_spec.rb
require 'rails_helper'

RSpec.describe TubeFromPlateCreation, type: :model do
  let(:child_purpose) { create(:tube_purpose) }
  let(:child) { create(:tube) }
  let(:parent) { create(:plate) }
  let(:tube_creation) { described_class.new(child_purpose:, parent:) }

  describe 'associations' do
    it { is_expected.to belong_to(:child).class_name('Tube') }
    it { is_expected.to belong_to(:parent).class_name('Plate') }
  end

  describe '#target_for_ownership' do
    it 'returns the child tube' do
      tube_creation.child = child
      expect(tube_creation.send(:target_for_ownership)).to eq(child)
    end
  end

  describe '#children' do
    it 'returns an array with the child tube' do
      tube_creation.child = child
      expect(tube_creation.send(:children)).to eq([child])
    end
  end

  describe '#create_children!' do
    it 'creates a child tube using the child_purpose' do
      expect { tube_creation.send(:create_children!) }.to change(Tube, :count).by(1)
    end

    it 'assigns the created tube to the child' do
      tube_creation.send(:create_children!)
      expect(tube_creation.child).to be_present
    end

    it 'sets the purpose of the created tube to the child_purpose' do
      tube_creation.send(:create_children!)
      expect(tube_creation.child.purpose).to eq(child_purpose)
    end
  end
end
