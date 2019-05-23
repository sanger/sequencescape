# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aker::Job, type: :model, aker: true do
  it 'is not valid without an Aker Job ID' do
    expect(build(:aker_job, aker_job_id: nil)).not_to be_valid
  end

  it 'is not valid without an Aker Job Url' do
    expect(build(:aker_job, aker_job_url: nil)).not_to be_valid
  end

  it 'is valid with both and Aker Job Id and an Aker Job Url' do
    expect(build(:aker_job)).to be_valid
  end

  it '#as_json should include id and aker_job_id only' do
    job = create(:aker_job)
    expect(job.as_json).to eq('job': { 'id': job.id, 'aker_job_id': job.aker_job_id })
  end
end
