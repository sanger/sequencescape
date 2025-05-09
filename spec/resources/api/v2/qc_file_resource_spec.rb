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
end
