# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabwhereReception do

  MockResponse ||= Struct.new(:valid?, :error)
  
  let!(:user) { create(:user, swipecard_code: '12345') }
  let(:plate) { create(:plate) }
  let(:location) { 'DN123456' }

  it 'records an event' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(MockResponse.new(true,''))
    reception = LabwhereReception.new('12345', location, [plate.ean13_barcode])
    expect(reception.save).to be_truthy
    expect(plate.events.first.created_by).to eq(user.login)
  end
end
