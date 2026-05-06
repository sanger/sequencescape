# frozen_string_literal: true

require 'rails_helper'
require_dependency Rails.root.join('app/controllers/api/v2/orders_controller').to_s

RSpec.describe Api::V2::OrderProcessor do
  describe '#find_project' do
    subject(:find_project) { processor.send(:find_project) }

    let(:processor) { described_class.allocate }
    let(:project_uuid) { nil }
    let(:params) do
      ActionController::Parameters.new(
        data: {
          attributes: {
            project_uuid:
          }
        }
      )
    end

    before do
      allow(processor).to receive(:params).and_return(params)
    end

    context 'when project_uuid is not provided' do
      it 'returns nil' do
        expect(find_project).to be_nil
      end
    end

    context 'when project_uuid does not exist' do
      let(:project_uuid) { 'not-a-valid-uuid' }

      it 'raises an invalid field value error' do
        expect { find_project }.to raise_error(JSONAPI::Exceptions::InvalidFieldValue)
      end
    end

    context 'when project_uuid exists' do
      let(:project) { create(:project) }
      let(:project_uuid) { project.uuid }

      it 'returns the project' do
        expect(find_project).to eq(project)
      end
    end
  end
end
