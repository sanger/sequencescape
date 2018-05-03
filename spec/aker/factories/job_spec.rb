require 'rails_helper'

RSpec.describe Aker::Factories::WorkOrder, type: :model, aker: true do
  let(:params) { build(:aker_work_order_json).with_indifferent_access }

  it 'is valid with aker id and materials' do
    work_order = Aker::Factories::WorkOrder.new(params)
    expect(work_order).to be_valid
    expect(work_order.aker_id).to eq(params[:work_order_id])
    expect(work_order.product_name).to eq(params[:product_name])
    expect(work_order.product_version).to eq(params[:product_version])
    expect(work_order.product_uuid).to eq(params[:product_uuid])
    expect(work_order.project_uuid).to eq(params[:project_uuid])
    expect(work_order.project_name).to eq(params[:project_name])
    expect(work_order.cost_code).to eq(params[:cost_code])
    expect(work_order.comment).to eq(params[:comment])
    expect(work_order.desired_date).to eq(params[:desired_date])
    expect(work_order.status).to eq(params[:status])
    expect(work_order.data_release_uuid).to eq(params[:data_release_uuid])
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
    json = work_order.as_json[:work_order]
    Aker::Factories::WorkOrder::ATTRIBUTES.each do |attribute|
      expect(json[attribute]).to be_present
    end
    expect(json[:materials].count).to eq(work_order.materials.count)
  end

  it 'creating a work order with existing materials will find those existing materials' do
    params[:materials].each { |material| Aker::Factories::Material.create(material) }
    work_order = Aker::Factories::WorkOrder.create(params)
    work_order = Aker::WorkOrder.find_by(aker_id: work_order.aker_id)
    expect(work_order).to be_present
    expect(work_order.samples.count).to eq(params[:materials].count)
  end

  it 'is not valid unless there is a data release uuid (study)' do
    work_order = Aker::Factories::WorkOrder.new(params.except(:data_release_uuid))
    expect(work_order).to_not be_valid
  end

  it 'is not valid unless the study exists' do
    work_order = Aker::Factories::WorkOrder.new(params.merge(data_release_uuid: SecureRandom.uuid))
    expect(work_order).to_not be_valid
  end

  it 'is not valid unless the study is active' do
    study = create(:study_for_study_list_inactive)
    work_order = Aker::Factories::WorkOrder.new(params.merge(data_release_uuid: study.uuid))
    expect(work_order).to_not be_valid
  end
end
