# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpecificTubeCreation, type: :model do
  subject(:specific_tube_creation) { described_class.new(creation_parameters) }

  shared_examples 'a specific tube creator' do
    let(:child_purpose) { create(:tube_purpose) }
    let(:user) { create :user }
    let(:parent) { create :plate }

    describe '#save' do
      before { expect(subject.save).to (be true), -> { "Failed to save: #{subject.errors.full_messages}" } }

      let(:first_child) { subject.children.first }

      it 'creates one child' do
        expect(subject.children.count).to eq purpose_count
      end

      it 'creates a tube' do
        expect(first_child).to be_a Tube
      end

      it 'sets the purpose' do
        expect(first_child.purpose).to eq child_purpose
      end

      it 'sets expected names' do
        subject.children.each_with_index { |child, i| expect(child.name).to eq names[i] }
      end

      it 'sets plates as parents' do
        subject.children.each { |child| expect(child.parents).to include(parent) }
      end
    end
  end

  context 'with no custom names' do
    let(:names) { [nil] * purpose_count }
    let(:creation_parameters) { { user: user, child_purposes: [child_purpose] * purpose_count, parent: parent } }

    context 'with one child purpose' do
      let(:purpose_count) { 1 }

      it_behaves_like 'a specific tube creator'
    end

    context 'with two child purpose' do
      let(:purpose_count) { 2 }

      it_behaves_like 'a specific tube creator'
    end
  end

  context 'with custom names' do
    let(:names) { %w[example_1 example_2] }
    let(:purpose_count) { 2 }
    let(:tube_attributes) { names.map { |name| { name: name } } }
    let(:creation_parameters) do
      { user: user, child_purposes: [child_purpose] * purpose_count, parent: parent, tube_attributes: tube_attributes }
    end

    it_behaves_like 'a specific tube creator'
  end
end
