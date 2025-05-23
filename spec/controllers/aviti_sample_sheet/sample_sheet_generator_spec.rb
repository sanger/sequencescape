# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AvitiSampleSheet::SampleSheetGenerator do
  let(:sample) { instance_double(Sample, name: 'Sample_001') }
  let(:tag) { instance_double(Tag, oligo: 'GTGCTGTC') }
  let(:tag2) { instance_double(Tag, oligo: 'CGTCGTCC') }
  let(:study) { instance_double(Study, id: 42) }
  let(:aliquot) { instance_double(Aliquot, sample:, tag:, tag2:, study:) }

  let(:target_asset) { instance_double(Receptacle, aliquots: [aliquot]) }

  let(:request) { instance_double(Request, target_asset: target_asset, position: 1) }

  let(:batch) { instance_double(Batch, requests: [request]) }

  describe '.generate' do
    subject(:output) { described_class.generate(batch) }

    # rubocop:disable RSpec/MultipleExpectations
    it 'includes the [SETTINGS] section' do
      expect(output).to include('R1Adapter')
      expect(output).to include('R1AdapterTrim')
      expect(output).to include('R2Adapter')
      expect(output).to include('R2AdapterTrim')
    end

    it 'includes the PhiX control samples' do
      expect(output).to include('Adept_CB1')
      expect(output).to include('Adept_CB2')
      expect(output).to include('Adept_CB3')
      expect(output).to include('Adept_CB4')
    end

    it 'includes sample information from the batch' do
      expect(output).to include('Sample_001') # sample name
      expect(output).to include('GTGCTGTC') # tag1
      expect(output).to include('CGTCGTCC') # tag2
      expect(output).to include('1') # lane number
      expect(output).to include('42') # study id
    end

    it 'uses CRLF line endings' do
      expect(output).to include("\r\n")
    end

    it 'produces the correct number of lines' do
      expected_settings_lines = 7 # [SETTINGS], header, comment, 4 adapter rows
      expected_phix_lines = 6 # [SAMPLES], header, 4 phiX samples
      expected_sample_lines = 1 # comment + 1 sample row from mocked batch
      expect(output.split("\r\n").size).to eq(expected_settings_lines + expected_phix_lines + expected_sample_lines)
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
