require 'rails_helper'

RSpec.describe Accession::Request, type: :model, accession: true do
  include MockAccession

  let(:submission) { build(:accession_submission) }

  it 'should not be valid without a submission' do
    expect(Accession::Request.new(nil)).to_not be_valid
  end

  it 'should have a resource' do
    expect(Accession::Request.new(submission).resource).to_not be_nil
  end

  it 'should set the header and proxy' do
    proxy = configatron.disable_web_proxy
    configatron.proxy = 'mockproxy'

    configatron.disable_web_proxy = false
    request = Accession::Request.new(submission)
    expect(RestClient.proxy).to eq(configatron.proxy)
    expect(request.resource.options[:headers]).to have_key(:user_agent)

    configatron.disable_web_proxy = true
    request = Accession::Request.new(submission)
    expect(RestClient.proxy).to_not be_present
    expect(request.resource.options.key?(:headers)).to be_falsey

    configatron.disable_web_proxy = proxy
    configatron.proxy = nil
  end

  context '#post' do
    it 'should return nothing if the submission is not valid' do
      expect(Accession::Request.new(nil).post).to be_nil
    end

    it 'should return nothing if an error is raised' do
      request = Accession::Request.new(submission)
      allow(request.resource).to receive(:post)
        .with(submission.payload.files)
        .and_raise(StandardError)

      expect(request.post).to_not be_accessioned
    end

    it 'should return a successful response if accessioning is successful' do
      request = Accession::Request.new(submission)
      allow(request.resource).to receive(:post)
        .with(submission.payload.files)
        .and_return(successful_accession_response)

      expect(request.post).to be_accessioned
    end

    it 'should return a failure response if accessioning fails' do
      request = Accession::Request.new(submission)
      allow(request.resource).to receive(:post)
        .with(submission.payload.files)
        .and_return(failed_accession_response)

      expect(request.post).to_not be_accessioned
    end
  end
end
