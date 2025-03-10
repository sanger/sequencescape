# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LotType do
  context 'validating' do
    before { create(:lot) }

    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  it 'is validated', :aggregate_failures do
    expect(subject).to validate_presence_of :name
    expect(subject).to validate_presence_of :template_class
    expect(subject).to have_many :lots
    expect(subject).to belong_to :target_purpose
  end

  describe '#lot' do
    let(:lot_type) { create(:lot_type) }
    let(:user) { create(:user) }
    let(:template) { PlateTemplate.new }
    let(:lot) { lot_type.create!(template: template, user: user, lot_number: '123456789', received_at: '2014-02-01') }

    context 'create' do
      it 'change Lot.count by 1' do
        expect { lot }.to change(Lot, :count).by 1
      end

      it 'set the lot properties' do
        expect(lot.user).to eq(user)
        expect(lot.lot_number).to eq('123456789')
      end
    end
  end
end
