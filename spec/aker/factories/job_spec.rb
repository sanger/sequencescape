# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe Aker::Factories::Job, type: :model, aker: true do
  include BarcodeHelper
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
  before do
    Aker::Material.config = my_config
    mock_plate_barcode_service
    build(:sample_tube_purpose, name: 'Standard sample').save
  end

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
    expect(job.priority).to eq(params[:priority])
    expect(job.data_release_uuid).to eq(params[:data_release_uuid])
    expect(job.modules).to eq(params[:modules])
    expect(job.container).to eq(params[:container])
    expect(job.materials.count).to eq(params[:materials].count)
  end

  it 'must have an aker job id which is a number' do
    job = Aker::Factories::Job.new(params.except(:job_id))
    expect(job).not_to be_valid
  end

  it 'must have some materials' do
    job = Aker::Factories::Job.new(params.except(:materials))
    expect(job).not_to be_valid

    job = Aker::Factories::Job.new(params.merge(materials: []))
    expect(job).not_to be_valid
  end

  it 'is not valid unless all of the materials are valid' do
    job = Aker::Factories::Job.new(params.merge(materials: params[:materials].push(params[:materials].first.except(:_id))))
    expect(job).not_to be_valid
  end

  context 'when trying to update data from aker into ss' do
    before do
      job = Aker::Factories::Job.create(params)
      expect(job).to be_present
      @material = job.samples.first
      @material.sample_metadata.update(sample_common_name: 'Some name')
      @material.sample_metadata.reload
      expect(@material.sample_metadata.sample_common_name).to eq('Some name')
    end

    context 'when the update from aker to ss is defined' do
      before do
        Aker::Material.config = %(
          sample_metadata.sample_common_name  <=   common_name
        )
      end

      it '#create updates the materials if they already exist' do
        job = Aker::Factories::Job.create(params.merge(job_uuid: SecureRandom.uuid))
        expect(job).to be_present
        @material.sample_metadata.reload
        expect(@material.sample_metadata.sample_common_name).not_to eq('Some name')
      end
    end

    context 'when the update from aker to ss is not defined' do
      before do
        Aker::Material.config = ''
      end

      it '#create does not update the materials data if they already exist' do
        job = Aker::Factories::Job.create(params.merge(job_uuid: SecureRandom.uuid))
        expect(job).to be_present
        @material.sample_metadata.reload
        expect(@material.sample_metadata.sample_common_name).to eq('Some name')
      end
    end
  end

  it '#create persists the job if it is valid' do
    job = Aker::Factories::Job.create(params)
    expect(job).to be_present
    job = Aker::Job.find_by(aker_job_id: job.aker_job_id)
    expect(job).to be_present
    expect(job.samples.count).to eq(params[:materials].count)
    expect(Aker::Factories::Job.create(params.except(:materials))).to be_nil
  end

  it '#create will fail if the materials exist but the containers has changed' do
    Aker::Factories::Job.create(params)
    wrong_container_params = params[:container].merge(barcode: 'WRONG', address: 'BAD')
    expect do
      Aker::Factories::Job.create(params.merge(job_uuid: SecureRandom.uuid, container: wrong_container_params))
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'creating a job with existing materials will find those existing materials' do
    study = create :study
    params[:materials].each do |material|
      container = Aker::Factories::Container.new(params[:container].merge(address: material[:address]))
      m = Aker::Factories::Material.new(material, container, study)
      m.create
    end
    job = Aker::Factories::Job.create(params)
    job = Aker::Job.find_by(aker_job_id: job.aker_job_id)
    expect(job).to be_present
    expect(job.samples.count).to eq(params[:materials].count)
  end

  it 'creating a job will set the samples in the study specified (when provided)' do
    study = create :study
    create :uuid, external_id: study.uuid
    params[:data_release_uuid] = study.uuid
    job = Aker::Factories::Job.create(params)
    job = Aker::Job.find_by(aker_job_id: job.aker_job_id)
    expect(job).to be_present
    expect(job.samples.map(&:studies).flatten.uniq.sort).to eq([study])
  end

  it 'creating a job with existing materials will add the study to the list of studies for the sample' do
    study = create :study
    create :uuid, external_id: study.uuid
    params[:data_release_uuid] = study.uuid
    params[:materials].each do |material|
      container = Aker::Factories::Container.new(params[:container].merge(address: material[:address]))
      Aker::Factories::Material.new(material, container, study).create
    end
    job = Aker::Factories::Job.new(params).create
    job = Aker::Job.find_by(aker_job_id: job.aker_job_id)
    expect(job).to be_present
    expect(job.samples.map(&:studies).flatten.uniq.sort).to eq([study].sort)
  end

  it 'is not valid unless there is a data release uuid (study)' do
    job = Aker::Factories::Job.new(params.except(:data_release_uuid))
    expect(job).not_to be_valid
  end

  it 'is not valid unless the study exists' do
    job = Aker::Factories::Job.new(params.merge(data_release_uuid: SecureRandom.uuid))
    expect(job).not_to be_valid
  end

  it 'is not valid unless the study is active' do
    study = create(:study_for_study_list_inactive)
    job = Aker::Factories::Job.new(params.merge(data_release_uuid: study.uuid))
    expect(job).not_to be_valid
  end

  it 'ignores extra container params' do
    extra_container_params = params[:container].merge(container_id: 123, num_of_rows: 1, num_of_cols: 2)
    job = Aker::Factories::Job.create(params.merge(container: extra_container_params))
    job = Aker::Job.find_by(aker_job_id: job.aker_job_id)
    expect(job).to be_present
  end
end
