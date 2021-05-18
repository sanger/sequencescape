# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Jobs', type: :feature, aker: true do
  let!(:jobs) { create_list(:aker_job_with_samples, 5) }
  let!(:job) { jobs.first }
  let(:get_url) { job.aker_job_url }
  let(:request) { RestClient::Request.new(method: :get, url: get_url) }
  let(:job_json) { File.read(File.join('spec', 'data', 'aker', 'job.json')) }

  it 'view all jobs' do
    visit aker_jobs_path
    expect(find('.jobs')).to have_css('.job', count: 5)
  end

  context 'existing job' do
    context 'active' do
      before do
        allow(RestClient::Request).to receive(:execute)
          .with(verify_ssl: false, method: :get, url: get_url, headers: { content_type: :json }, proxy: nil)
          .and_return(RestClient::Response.create(job_json, Net::HTTPResponse.new('1.1', 200, ''), request))
      end

      it 'view a job' do
        visit aker_job_path(job.job_uuid)
        expect(page).to have_content('Jobs')
        json = JSON.parse(job_json)['job']
        within('.job') do
          expect(page).to have_content(json['product_name'])
          expect(page).to have_content(json['product_version'])
          expect(page).to have_content(json['product_uuid'])
          expect(page).to have_content(json['project_uuid'])
          expect(page).to have_content(json['project_name'])
          expect(page).to have_content(json['cost_code'])
          expect(page).to have_content(json['comment'])
          expect(page).to have_content(json['priority'])
          expect(page).to have_content(json['status'])
          expect(page).to have_css('.sample', count: job.samples.count)
        end
      end
    end
  end
end
