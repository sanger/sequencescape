# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Cache, type: :model, sample_manifest_excel: true, sample_manifest: true do
  let(:cache) { described_class.new(instance_double(SampleManifestExcel::Upload::Base)) }

  describe '#fetch' do
    context 'when it is uncached' do
      it 'returns the value of the block' do
        expect(cache.fetch(:test, 'this') { 'result' }).to eq 'result'
      end
    end

    context 'when it is cached' do
      before { cache.fetch(:test, 'this') { 'result' } }

      it 'returns the original value of the block without calling the new one' do
        expect(cache.fetch(:test, 'this') { raise 'This should not be called' }).to eq 'result'
      end
    end

    context 'when it is nil' do
      before { cache.fetch(:test, 'this') { nil } }

      it 'returns the original value of the block without calling the new one' do
        expect(cache.fetch(:test, 'this') { raise 'This should not be called' }).to be_nil
      end
    end
  end
end
