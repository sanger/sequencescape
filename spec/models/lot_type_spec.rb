# frozen_string_literal: true

require 'rails_helper'
require 'broadcast_event/lab_event'

RSpec.describe LotType do
  context 'validating' do
    setup do
      create :lot
    end

    it { should validate_uniqueness_of :name }
  end

  it 'is validated', :aggregate_failures do
    is_expected.to validate_presence_of :name
    is_expected.to validate_presence_of :template_class
    is_expected.to have_many :lots
    is_expected.to belong_to :target_purpose
  end

  context '#lot' do
    let(:lot_type) { create :lot_type }
    let(:user) { create :user }
    let(:template) { PlateTemplate.new }
    let(:lot) { lot_type.create!(template: template, user: user, lot_number: '123456789', received_at: '2014-02-01') }

    context 'create' do
      it 'change Lot.count by 1' do
        expect { lot }.to change { Lot.count }.by 1
      end

      it 'set the lot properties' do
        assert_equal user, lot.user
        assert_equal '123456789', lot.lot_number
      end
    end
  end
end
