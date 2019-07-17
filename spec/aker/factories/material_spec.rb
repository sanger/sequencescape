# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aker::Factories::Material, type: :model, aker: true do
  include BarcodeHelper
  before do
    Aker::Material.config = my_config
    mock_plate_barcode_service
  end

  let(:my_config) do
    %(
    sample_metadata.gender              <=   gender
    sample_metadata.donor_id            <=   donor_id
    sample_metadata.supplier_name       <=   supplier_name
    sample_metadata.phenotype           <=   phenotype
    sample_metadata.sample_common_name  <=   common_name
    well_attribute.measured_volume      <=>  volume
    well_attribute.concentration        <=>  concentration
    )
  end

  let(:json) do
    file = File.read(File.join('spec', 'data', 'aker', 'job.json'))
    JSON.parse(file).with_indifferent_access
  end
  let(:params) do
    json[:job][:materials].first
  end
  let(:container_params) do
    json[:job][:container]
  end

  let(:container) { Aker::Factories::Container.new(container_params.merge(address: params[:address])) }
  let(:study) { create :study }

  it 'is valid with all relevant attributes' do
    material = Aker::Factories::Material.new(params, container, study)
    sample = material.create

    expect(sample).to be_valid

    expect(sample.uuid).to eq(params[:_id])
    expect(sample.name).to match(Regexp.new("#{study.abbreviation}\\d+"))
    s = sample.sample_metadata
    expect(s.supplier_name).to eq(params[:supplier_name])
    expect(s.gender.downcase).to eq(params[:gender].downcase)
    expect(s.donor_id).to eq(params[:donor_id])
    expect(s.phenotype).to eq(params[:phenotype])
    expect(s.sample_common_name).to eq(params[:common_name])
    expect(sample.wells.count).to eq(1)
  end

  it 'is not valid without a name' do
    material = Aker::Factories::Material.new(params.except('_id'), container, study)
    expect(material).not_to be_valid
  end

  it 'is not valid without a gender' do
    material = Aker::Factories::Material.new(params.except('gender'), container, study)
    expect(material).not_to be_valid
  end

  it 'is not valid without a container' do
    material = Aker::Factories::Material.new(params, nil, study)
    expect(material).not_to be_valid
  end

  it 'is not valid unless the container is valid' do
    material = Aker::Factories::Material.new(params,
                                             Aker::Factories::Container.new(container_params.merge(address: params[:address]).except(:barcode)),
                                             study)
    material.create

    expect(material).not_to be_valid
  end

  it 'sets the container for the sample' do
    material = Aker::Factories::Material.new(params, container, study)
    material.create
    expect(material.sample.container).to eq(container.model)
  end

  it '#create persists the material if it is valid' do
    material = Aker::Factories::Material.new(params, container, study)
    material.create
    expect(material).to be_present
    sample = Sample.include_uuid.find_by(uuids: { external_id: params[:_id] })
    expect(sample).to be_present
    expect(sample.wells.count).to eq(1)
    expect(Aker::Factories::Material.new(params.except('gender'), container, study).create).to be_nil
  end
end
