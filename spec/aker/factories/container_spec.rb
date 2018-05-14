require 'rails_helper'

RSpec.describe Aker::Factories::Container, type: :model, aker: true do
  let(:json) do
    file = File.read(File.join('spec', 'data', 'aker', 'job.json'))
    JSON.parse(file).with_indifferent_access
  end
  let(:material) do
    json[:job][:materials].first
  end
  let(:params) do
    json[:job][:container]
  end

  it 'is valid with barcode and address' do
    container = Aker::Factories::Container.new(params.merge(address: material[:address]))
    expect(container).to be_valid
    expect(container.barcode).to eq(params[:barcode])
    expect(container.address).to eq(material[:address])
  end

  it 'must have a barcode' do
    container = Aker::Factories::Container.new(params.except(:barcode))
    expect(container).to_not be_valid
  end

  it '#create persists the container if it is valid' do
    container = Aker::Factories::Container.create(params)
    expect(container).to be_present
    expect(Aker::Container.find_by(barcode: container.barcode)).to be_present

    container = Aker::Factories::Container.create(params.except(:barcode))
    expect(container).to be_nil
  end

  it '#create finds the container if it already exists' do
    ar_container = Aker::Container.create(params)
    container = Aker::Factories::Container.create(params)
    expect(container).to eq(ar_container)
  end

  it '#as_json returns the correct attributes' do
    container = Aker::Factories::Container.new(params)
    ar_container = container.create
    expect(container.as_json).to eq(ar_container.as_json)
  end
end
