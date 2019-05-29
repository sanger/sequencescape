require 'rails_helper'

RSpec.describe Accession::Request, type: :model, accession: true do
  include MockAccession

  let(:submission) { build(:accession_submission) }

  it 'is not valid without a submission' do
    expect(Accession::Request.new(nil)).not_to be_valid
  end

  it 'has a resource' do
    expect(Accession::Request.new(submission).resource).not_to be_nil
  end

  it 'sets the header and proxy' do
    proxy = configatron.disable_web_proxy
    configatron.proxy = 'mockproxy'

    configatron.disable_web_proxy = false
    request = Accession::Request.new(submission)
    expect(RestClient.proxy).to eq(configatron.proxy)
    expect(request.resource.options[:headers]).to have_key(:user_agent)

    configatron.disable_web_proxy = true
    request = Accession::Request.new(submission)
    expect(RestClient.proxy).not_to be_present
    expect(request.resource.options).not_to be_key(:headers)

    configatron.disable_web_proxy = proxy
    configatron.proxy = nil
  end

  context '#post' do
    it 'returns nothing if the submission is not valid' do
      expect(Accession::Request.new(nil).post).to be_nil
    end

    it 'returns nothing if an error is raised' do
      request = Accession::Request.new(submission)
      allow(request.resource).to receive(:post)
        .with(submission.payload.files)
        .and_raise(StandardError)

      expect(request.post).not_to be_accessioned
    end

    it 'returns a successful response if accessioning is successful' do
      request = Accession::Request.new(submission)
      allow(request.resource).to receive(:post)
        .with(submission.payload.files)
        .and_return(successful_accession_response)

      expect(request.post).to be_accessioned
    end

    it 'returns a failure response if accessioning fails' do
      request = Accession::Request.new(submission)
      allow(request.resource).to receive(:post)
        .with(submission.payload.files)
        .and_return(failed_accession_response)

      expect(request.post).not_to be_accessioned
    end
  end
end
