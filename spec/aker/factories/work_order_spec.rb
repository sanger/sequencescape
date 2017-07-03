require 'rails_helper'

RSpec.describe Aker::Factories::WorkOrder, type: :model, aker: true do
  let(:params) do
    file = File.read(File.join('spec', 'data', 'aker', 'work_order.json'))
    JSON.parse(file).with_indifferent_access[:work_order]
  end

  it 'is valid with aker id and materials' do
    work_order = Aker::Factories::WorkOrder.new(params)
    expect(work_order).to be_valid
    expect(work_order.aker_id).to eq(params[:work_order_id])
    expect(work_order.materials.count).to eq(params[:materials].count)
  end

  it 'must have an aker id which is a number' do
    work_order = Aker::Factories::WorkOrder.new(params.except(:work_order_id))
    expect(work_order).to_not be_valid
  end

  it 'must have some materials' do
    work_order = Aker::Factories::WorkOrder.new(params.except(:materials))
    expect(work_order).to_not be_valid

    work_order = Aker::Factories::WorkOrder.new(params.merge(materials: []))
    expect(work_order).to_not be_valid
  end

  it 'is not valid unless all of the materials are valid' do
    work_order = Aker::Factories::WorkOrder.new(params.merge(materials: params[:materials].push(params[:materials].first.except(:_id))))
    expect(work_order).to_not be_valid
  end

  it '#create persists the work order if it is valid' do
    work_order = Aker::Factories::WorkOrder.create(params)
    expect(work_order).to be_present
    work_order = Aker::WorkOrder.find_by(aker_id: work_order.aker_id)
    expect(work_order).to be_present
    expect(work_order.samples.count).to eq(params[:materials].count)

    expect(Aker::Factories::WorkOrder.create(params.except(:materials))).to be_nil
  end

  it '#as_json returns work order' do
    work_order = Aker::Factories::WorkOrder.new(params)
    ar_work_order = work_order.create
    expect(work_order.as_json).to eq(ar_work_order.as_json)
  end
end
