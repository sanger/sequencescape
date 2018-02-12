# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe TransferRequest::Initial do
  let(:source_asset) { create :well_with_sample_and_without_plate }
  let(:target_asset) { create :well }
  let(:example_study) { create :study }
  let(:example_project) { create :project }
  let!(:library_request) do
    create :library_request,
           asset: source_asset,
           initial_study: example_study,
           initial_project: example_project,
           state: library_state
  end

  subject do
    create :initial_transfer_request,
           asset: source_asset,
           target_asset: target_asset,
           submission: library_request.submission
  end

  context 'with a pending library request' do
    let(:library_state) { 'pending' }

    it 'sets the target aliquots to the library request study and project' do
      subject
      expect(target_asset.aliquots.first.study).to eq(example_study)
      expect(target_asset.aliquots.first.project).to eq(example_project)
    end

    it 'sets appropriate metadata on the aliquots' do
      subject
      expect(target_asset.aliquots.first.library_type).to eq(library_request.library_type)
      expect(target_asset.aliquots.first.insert_size).to eq(library_request.insert_size)
    end

    it 'starts the library request when started' do
      subject.start!
      expect(library_request.reload.state).to eq('started')
    end

    # Users can jump straight to passed from pending. So we need to handle that as well.
    it 'starts the library request when passed' do
      subject.pass!
      expect(library_request.reload.state).to eq('started')
    end
  end

  context 'with a started outer request' do
    let(:library_state) { 'started' }

    it 'transitions without changing the library request' do
      subject.pass!
      expect(library_request.reload.state).to eq('started')
    end
  end
end
