# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhiX::Stock, :phi_x do
  subject { build(:phi_x_stock, custom_options) }

  context 'with suitable options' do
    let(:custom_options) { {} } # Fallback to factory defaults

    it { is_expected.to be_valid }
  end

  context 'with no name' do
    let(:custom_options) { { name: '' } }

    it { is_expected.not_to be_valid }
  end

  context 'with no study' do
    let(:custom_options) { { study_id: nil } }

    it { is_expected.not_to be_valid }
  end

  context 'with unknown tags option' do
    let(:custom_options) { { tags: 'Do not exist' } }

    it { is_expected.not_to be_valid }
  end

  [0, -2, 'two'].each do |invalid_concentration|
    context "with the invalid concentration #{invalid_concentration}" do
      let(:custom_options) { { concentration: invalid_concentration } }

      it { is_expected.not_to be_valid }
    end
  end

  [0, -2, 'two', 1.5].each do |invalid_number|
    context "with the invalid number #{invalid_number}" do
      let(:custom_options) { { number: invalid_number } }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#save' do
    context 'with valid data' do
      subject(:save) { phi_x_stock.save }

      let(:phi_x_stock) do
        build(:phi_x_stock, number: 2, name: 'Example', concentration: '0.8', tags: tags, study_id: study_id)
      end

      let(:tags) { 'Single' }
      let(:study_id) { build_stubbed(:study).id }

      before { save }

      it { is_expected.to be true }

      it 'generates tubes according to the number supplied' do
        expect(phi_x_stock.created_stocks).to have(2).items
      end

      it 'generates PhiX Stock tubes' do
        expect(phi_x_stock.created_stocks).to all be_a LibraryTube
        expect(phi_x_stock.created_stocks).to all have_attributes(purpose: PhiX.stock_purpose)
      end

      it 'names tubes appropriately' do
        expect(phi_x_stock.created_stocks).to all have_attributes(name: a_string_starting_with('Example #'))
      end

      it 'sets the concentration' do
        expect(phi_x_stock.created_stocks).to all have_attributes(concentration: 0.8)
      end

      it 'generates an aliquot in each tube' do
        phi_x_stock.created_stocks.each { |tube| expect(tube.aliquots).to have(1).items }
      end

      it 'sets study id the aliquot in each tube' do
        phi_x_stock.created_stocks.each { |tube| expect(tube.aliquots).to all have_attributes(study_id:) }
      end

      it 'generates an aliquot with PhiX sample' do
        phi_x_stock.created_stocks.each { |tube| expect(tube.aliquots).to all have_attributes(sample: PhiX.sample) }
      end

      context 'with Single tags' do
        let(:tags) { 'Single' }
        let(:expected_tag) { TagGroup.find_by!(name: 'Control Tag Group 888').tags.find_by!(oligo: 'ACAACGCAAT') }

        it 'generates an aliquot with an i7 tag' do
          phi_x_stock.created_stocks.each do |tube|
            expect(tube.aliquots).to all have_attributes(tag: expected_tag, tag2: nil, library_id: tube.receptacle.id)
          end
        end
      end

      context 'with Dual tags' do
        let(:tags) { 'Dual' }
        let(:expected_tag) { TagGroup.find_by!(name: 'Control Tag Group 888').tags.find_by!(oligo: 'TGTGCAGC') }
        let(:expected_tag_2) { TagGroup.find_by!(name: 'Control Tag Group 888').tags.find_by!(oligo: 'ACTGATGT') }

        it 'generates an aliquot with an i5 and i7 tag' do
          phi_x_stock.created_stocks.each do |tube|
            expect(tube.aliquots).to all have_attributes(
              tag: expected_tag,
              tag2: expected_tag_2,
              library_id: tube.receptacle.id
            )
          end
        end
      end
    end

    context 'with invalid data' do
      let(:phi_x_stock) { build(:phi_x_stock, number: -2) }

      it 'returns false' do
        expect(phi_x_stock.save).to be false
      end
    end
  end
end
