# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aker::Job, type: :model, aker: true do
  it 'is not valid without an Aker Job ID' do
    expect(build(:aker_job, aker_job_id: nil)).to_not be_valid
  end

  it '#as_json should include id and aker_job_id only' do
    job = create(:aker_job)
    expect(job.as_json).to eq('job': { 'id': job.id, 'aker_job_id': job.aker_job_id })
  end
end
