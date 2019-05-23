# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aker::JobsController, type: :request, aker: true do
  let!(:job) { create(:aker_job) }
  let(:url) { job.aker_job_url }
  let(:request) { RestClient::Request.new(method: :put, url: url) }

  it 'start a job' do
    allow(RestClient::Request).to receive(:execute).with(
      verify_ssl: false,
      method: :put,
      url: "#{url}/start",
      headers: { content_type: :json },
      proxy: nil
    ).and_return(
      RestClient::Response.create({ job: { id: job.aker_job_id } }.to_json,
                                  Net::HTTPResponse.new('1.1', 200, ''), request)
    )

    put start_aker_job_path(job.job_uuid)

    expect(response).to have_http_status :ok
  end

  it 'complete a job' do
    allow(RestClient::Request).to receive(:execute).with(
      verify_ssl: false,
      method: :put,
      url: "#{url}/complete",
      payload: {
        job: { job_id: job.aker_job_id,
               updated_materials: [], new_materials: [], containers: [] }
      }.to_json,
      headers: { content_type: :json },
      proxy: nil
    ).and_return(
      RestClient::Response.create({ job: { id: job.aker_job_id,
                                           updated_materials: [], new_materials: [], containers: [] } }.to_json,
                                  Net::HTTPResponse.new('1.1', 200, ''), request)
    )

    put complete_aker_job_path(job.job_uuid), params: { comment: 'Complete it' }

    expect(response).to have_http_status :ok
  end

  it 'cancel a job' do
    allow(RestClient::Request).to receive(:execute).with(
      verify_ssl: false,
      method: :put,
      url: "#{url}/cancel",
      payload: {
        job: { job_id: job.aker_job_id,
               updated_materials: [], new_materials: [], containers: [] }
      }.to_json,
      headers: { content_type: :json },
      proxy: nil
    ).and_return(RestClient::Response.create({
      job: { id: job.aker_job_id,
             updated_materials: [], new_materials: [], containers: [] }
    }.to_json,
                                             Net::HTTPResponse.new('1.1', 200, ''), request))

    put cancel_aker_job_path(job.job_uuid), params: { comment: 'Cancel it' }

    expect(response).to have_http_status :ok
  end
end
