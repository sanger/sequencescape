require 'rails_helper'
require 'date'

RSpec.describe Deployed::RepoData do
  subject(:repo_data) { described_class.new }

  describe '#release_timestamp' do
    before do
      # freeze time to ensure consistent test results
      allow(DateTime).to receive(:now).and_return(DateTime.parse('2025-07-18T12:00:00'))
      allow(repo_data).to receive(:read_file).with('RELEASE').and_return(file_contents) # rubocop:disable RSpec/SubjectStub
    end

    context 'when a RELEASE file exists with a timestamp' do
      let(:file_contents) { '20231025123000' }

      it 'returns the correct ISO 8601 formatted time' do
        expect(repo_data.release_timestamp).to eq('2023-10-25T12:30:00')
      end
    end

    context 'when a RELEASE file exists with a non-timestamp string' do
      let(:file_contents) { 'release-v1.0.0' }

      it 'returns the current time in ISO 8601 format' do
        expect(repo_data.release_timestamp).to eq('2025-07-18T12:00:00')
      end
    end

    context 'when a RELEASE file does not exist' do
      let(:file_contents) { '' }

      it 'returns the current time in ISO 8601 format' do
        expect(repo_data.release_timestamp).to eq('2025-07-18T12:00:00')
      end
    end
  end
end
