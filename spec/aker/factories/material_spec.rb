require 'rails_helper'

RSpec.describe Aker::Factories::Material, type: :model, aker: true do
  let(:params) do
    file = File.read(File.join('spec', 'data', 'aker', 'work_order.json'))
    JSON.parse(file).with_indifferent_access[:work_order][:materials].first
  end

  it 'is valid with all relevant attributes' do
    material = Aker::Factories::Material.new(params)
    expect(material).to be_valid
    expect(material.name).to eq(params[:_id])
    expect(material.gender).to eq(params[:gender])
    expect(material.donor_id).to eq(params[:donor_id])
    expect(material.phenotype).to eq(params[:phenotype])
    expect(material.sample_common_name).to eq(params[:common_name])
    expect(material.container).to_not be_nil
  end

  it 'is not valid without a name' do
    material = Aker::Factories::Material.new(params.except('_id'))
    expect(material).to_not be_valid
  end

  it 'is not valid without a gender' do
    material = Aker::Factories::Material.new(params.except('gender'))
    expect(material).to_not be_valid
  end

  it 'is not valid without a container' do
    material = Aker::Factories::Material.new(params.except('container'))
    expect(material).to_not be_valid
  end

  it 'is not valid unless the container is valid' do
    material = Aker::Factories::Material.new(params.merge(container: params[:container].except(:barcode)))
    expect(material).to_not be_valid
  end

  it '#create persists the material if it is valid' do
    material = Aker::Factories::Material.create(params)
    expect(material).to be_present
    sample = Sample.find_by(name: material.name)
    expect(sample).to be_present
    expect(sample.container).to be_present
    expect(Aker::Factories::Material.create(params.except('gender'))).to be_nil
  end

  it '#as_json returns the correct attributes' do
    material = Aker::Factories::Material.new(params)
    material.create
    expect(material.as_json).to eq( { _id: material.name, gender: material.gender, donor_id: material.donor_id, 
                                      phenotype: material.phenotype, common_name: material.sample_common_name, container: material.container.as_json
                                    }
                                  )
  end
end
