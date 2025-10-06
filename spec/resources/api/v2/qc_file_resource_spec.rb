# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/qc_file_resource'

RSpec.describe Api::V2::QcFileResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:qc_file) }

  # Model Name
  it { is_expected.to have_model_name 'QcFile' }

  # Attributes
  it { is_expected.to have_readonly_attribute :content_type }
  it { is_expected.to have_write_once_attribute :contents }
  it { is_expected.to have_readonly_attribute :created_at }
  it { is_expected.to have_write_once_attribute :filename }
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readonly_attribute :size }

  # Relationships
  it { is_expected.to have_a_write_once_has_one(:labware).with_class_name('Labware') }

  # Filters
  it { is_expected.to filter(:uuid) }

  # Custom methods
  describe '#self.create' do
    let(:tempfile) { Tempfile.new }
    let(:filename) { 'filename' }
    let(:context) { { tempfile:, filename: } }
    let(:qc_file) { QcFile.new }

    it 'creates the new QcFile with uploaded_data' do
      allow(QcFile).to receive(:new).and_call_original

      described_class.create(context)

      expect(QcFile).to have_received(:new).with({ uploaded_data: { tempfile:, filename: } })
    end

    it 'creates the new resource with the new QcFile' do
      allow(QcFile).to receive(:new).and_return(qc_file)
      allow(described_class).to receive(:new).and_call_original

      described_class.create(context)

      expect(described_class).to have_received(:new).with(qc_file, context)
    end
  end

  describe '#contents' do
    let(:utf_8) { 'UTF-8' } # rubocop:disable Naming/VariableNumber
    let(:encoding) { utf_8 }
    let(:encoded_contents) { contents.encode(encoding) }
    let(:resource_model) { create(:qc_file, contents: encoded_contents) }

    context 'when the contents are not encoded and contain invalid bytes' do
      let(:encoding) { 'ASCII-8BIT' }
      let(:contents) { 'GIF87a this looks like a gif ²'.b }

      it 'returns the string as is' do
        expect(resource.contents).to eq("GIF87a this looks like a gif \xC2\xB2")
      end

      it 'returns the contents as a binary representation in UTF-8 for API usage' do
        expect(resource.contents.encoding.name).to eq(utf_8)
      end
    end

    context 'when the contents are not encoded, but decipherable' do
      let(:encoding) { 'ASCII-8BIT' }
      let(:contents) do
        "The coefficient of micro-determination (\xCE\xBC\xC2\xB2). Yukihiro Matsumoto " \
        "\xE3\x81\xBE\xE3\x81\xA4\xE3\x82\x82\xE3\x81\xA8\xE3\x82\x86\xE3\x81\x8D\xE3\x81\xB2\xE3\x82\x8D".b
      end

      it 'returns the string, with invalid characters replaced' do
        expect(resource.contents).to eq('The coefficient of micro-determination (μ²). Yukihiro Matsumoto まつもとゆきひろ')
      end

      it 'returns the contents as UTF-8' do
        expect(resource.contents.encoding.name).to eq(utf_8)
      end
    end
  end
end
