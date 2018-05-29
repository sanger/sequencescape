# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aker::Factories::Job, type: :model, aker: true do
  let(:params) { build(:aker_job_json).to_h.with_indifferent_access }

  it 'is valid with aker job id, data_release_uuid and materials' do
    job = Aker::Factories::Job.new(params)
    expect(job).to be_valid
    expect(job.aker_job_id).to eq(params[:job_id])
    expect(job.work_order_id).to eq(params[:work_order_id])
    expect(job.process_name).to eq(params[:process_name])
    expect(job.process_uuid).to eq(params[:process_uuid])
    expect(job.product_name).to eq(params[:product_name])
    expect(job.product_version).to eq(params[:product_version])
    expect(job.product_uuid).to eq(params[:product_uuid])
    expect(job.project_uuid).to eq(params[:project_uuid])
    expect(job.project_name).to eq(params[:project_name])
    expect(job.cost_code).to eq(params[:cost_code])
    expect(job.comment).to eq(params[:comment])
    expect(job.desired_date).to eq(params[:desired_date])
    expect(job.data_release_uuid).to eq(params[:data_release_uuid])
    expect(job.modules).to eq(params[:modules])
    expect(job.container).to eq(params[:container])
    expect(job.materials.count).to eq(params[:materials].count)
  end

  it 'must have an aker job id which is a number' do
    job = Aker::Factories::Job.new(params.except(:job_id))
    expect(job).to_not be_valid
  end

  it 'must have some materials' do
    job = Aker::Factories::Job.new(params.except(:materials))
    expect(job).to_not be_valid

    job = Aker::Factories::Job.new(params.merge(materials: []))
    expect(job).to_not be_valid
  end

  it 'is not valid unless all of the materials are valid' do
    job = Aker::Factories::Job.new(params.merge(materials: params[:materials].push(params[:materials].first.except(:_id))))
    expect(job).to_not be_valid
  end

  it '#create persists the job if it is valid' do
    job = Aker::Factories::Job.create(params)
    expect(job).to be_present
    job = Aker::Job.find_by(aker_job_id: job.aker_job_id)
    expect(job).to be_present
    expect(job.samples.count).to eq(params[:materials].count)
    expect(Aker::Factories::Job.create(params.except(:materials))).to be_nil
  end

  it '#as_json returns job' do
    job = Aker::Factories::Job.new(params)
    json = job.as_json[:job]
    Aker::Factories::Job::ATTRIBUTES.each do |attribute|
      expect(json[attribute]).to be_present
    end
    expect(json[:materials].count).to eq(job.materials.count)
  end

  it 'creating a job with existing materials will find those existing materials' do
    params[:materials].each { |material| Aker::Factories::Material.create(material) }
    job = Aker::Factories::Job.create(params)
    job = Aker::Job.find_by(aker_job_id: job.aker_job_id)
    expect(job).to be_present
    expect(job.samples.count).to eq(params[:materials].count)
  end

  it 'is not valid unless there is a data release uuid (study)' do
    job = Aker::Factories::Job.new(params.except(:data_release_uuid))
    expect(job).to_not be_valid
  end

  it 'is not valid unless the study exists' do
    job = Aker::Factories::Job.new(params.merge(data_release_uuid: SecureRandom.uuid))
    expect(job).to_not be_valid
  end

  it 'is not valid unless the study is active' do
    study = create(:study_for_study_list_inactive)
    job = Aker::Factories::Job.new(params.merge(data_release_uuid: study.uuid))
    expect(job).to_not be_valid
  end
end
