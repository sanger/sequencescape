# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe 'Jobs', type: :feature, aker: true do
  include BarcodeHelper
  before do
    @purpose = FactoryBot.create :aker_plate_purpose
    mock_plate_barcode_service
  end

  let!(:jobs) do
    create_list(:aker_job_with_samples, 5)
  end
  let!(:job) { jobs.first }
  let(:get_url) { job.aker_job_url }
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
        allow(RestClient::Request).to receive(:execute).with(verify_ssl: false, method: :get, url: get_url, headers: { content_type: :json }, proxy: nil).and_return(RestClient::Response.create(job_json, Net::HTTPResponse.new('1.1', 200, ''), request))
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
          expect(page).to have_content(json['priority'])
          expect(page).to have_content(json['status'])
          expect(page).to have_css('.sample', count: job.samples.count)
        end
      end
    end
  end
end
