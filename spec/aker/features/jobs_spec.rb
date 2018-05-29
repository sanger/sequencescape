# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Jobs', type: :feature, aker: true do
  let!(:jobs) { create_list(:aker_job_with_samples, 5) }
  let!(:job) { jobs.first }
  let(:get_url) { "#{Rails.configuration.aker['urls']['work_orders']}/jobs/#{job.aker_job_id}" }
  let(:request) { RestClient::Request.new(method: :get, url: get_url) }
  let(:job_json) do
    File.read(File.join('spec', 'data', 'aker', 'job.json'))
  end

  scenario 'view all jobs' do
    visit aker_jobs_path
    expect(find('.jobs')).to have_css('.job', count: 5)
  end

  context 'existing job' do
    context 'active' do
      before(:each) do
        allow(RestClient::Request).to receive(:execute).with(verify_ssl: false, method: :get, url: get_url, headers: { content_type: :json, Accept: :json }, proxy: nil).and_return(RestClient::Response.create(job_json, Net::HTTPResponse.new('1.1', 200, ''), request))
      end

      scenario 'view a job' do
        visit aker_job_path(job.aker_job_id)
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
          expect(page).to have_content(json['desired_date'])
          expect(page).to have_content(json['status'])
          expect(page).to have_css('.sample', count: job.samples.count)
        end
      end
    end
  end
end
