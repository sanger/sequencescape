# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/qc_file_resource'

RSpec.describe Api::V2::QcFileResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:qc_file) }

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
  describe '#self.create_with_tempfile' do
    let(:context) { {} }
    let(:tempfile) { Tempfile.new }
    let(:filename) { 'filename' }
    let(:qc_file) { QcFile.new }

    it 'creates the new QcFile with uploaded_data' do
      expect(QcFile).to receive(:new).with({ uploaded_data: { tempfile:, filename: } }).and_call_original

      described_class.create_with_tempfile(context, tempfile, filename)
    end

    it 'creates the new resource with the new QcFile' do
      allow(QcFile).to receive(:new).and_return(qc_file)
      expect(described_class).to receive(:new).with(qc_file, context)

      described_class.create_with_tempfile(context, tempfile, filename)
    end
  end
end
