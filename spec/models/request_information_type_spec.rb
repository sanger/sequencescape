# frozen_string_literal: true

RSpec.describe RequestInformationType do
  subject(:request_information_type) { described_class.new(name:, key:, label:, data_type:) }

  let(:label) { 'example' }

  describe '#value_for' do
    subject { request_information_type.value_for(request, batch) }

    let(:batch) { create(:batch) }
    let(:request) do
      create(:sequencing_request,
             request_metadata_attributes: {
               read_length: 76,
               created_at: Date.parse('2021-03-01')
             },
             batch:)
    end

    context 'when key is a request metadata' do
      let(:name) { 'Read Length' }
      let(:key) { 'read_length' }
      let(:data_type) { nil }

      it { is_expected.to eq '76' }
    end

    context 'when the data type is Date' do
      let(:name) { 'Created at' }
      let(:key) { 'created_at' }
      let(:data_type) { 'Date' }

      it { is_expected.to eq '01 March 2021' }
    end

    context 'when key is an event' do
      before do
        create(:lab_event, descriptors: { 'My event' => 'old value' }, eventful: request, batch:)
        create(:lab_event, descriptors: { 'My event' => 'new value' }, eventful: request, batch:)
      end

      let(:name) { 'My event' }
      let(:key) { 'My event' }
      let(:data_type) { nil }

      it { is_expected.to eq 'new value' }
    end

    context 'when key is unknown' do
      let(:name) { 'Not a key' }
      let(:key) { 'not_a_key' }
      let(:data_type) { nil }

      it { is_expected.to eq '' }
    end
  end
end
