# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AvitiSampleSheet::SampleSheetGenerator do
  let(:sample) { instance_double(Sample, name: 'Sample_001') }
  let(:sample2) { instance_double(Sample, name: 'Sample_002') }
  let(:study) { instance_double(Study, id: 42) }
  let(:study2) { instance_double(Study, id: 55) }
  let(:aliquot) do
    instance_double(
      Aliquot,
      sample: sample,
      tag: instance_double(Tag, oligo: 'GTGCTGTC'),
      tag2: instance_double(Tag, oligo: 'CGTCGTCC'),
      study: study
    )
  end
  let(:aliquot2) do
    instance_double(
      Aliquot,
      sample: sample2,
      tag: instance_double(Tag, oligo: 'TTTCCCG'),
      tag2: instance_double(Tag, oligo: 'CCCTTTG'),
      study: study
    )
  end

  let(:target_asset) { instance_double(Receptacle, aliquots: [aliquot]) }
  let(:target_asset2) { instance_double(Receptacle, aliquots: [aliquot2]) }

  let(:request) { instance_double(Request, target_asset: target_asset, position: 1, failed?: false) }
  let(:request2) { instance_double(Request, target_asset: target_asset2, position: 2, failed?: false) }

  let(:batch) { instance_double(Batch, requests: [request, request2]) }

  describe '.generate' do
    subject(:output) { described_class.generate(batch) }

    let(:expected_settings_lines) { 7 } # [SETTINGS], header, comment, 4 adapter rows
    let(:expected_phix_lines) { 6 }     # [SAMPLES], header, 4 phiX samples

    context 'with two requests containing different samples' do
      # rubocop:disable RSpec/MultipleExpectations
      it 'includes the [SETTINGS] section' do
        expect(output).to include('R1Adapter')
        expect(output).to include('R1AdapterTrim')
        expect(output).to include('R2Adapter')
        expect(output).to include('R2AdapterTrim')
      end

      it 'includes the PhiX control samples' do
        expect(output).to include('PhiX_Third')
        expect(output).to include('PhiX_Third')
        expect(output).to include('PhiX_Third')
        expect(output).to include('PhiX_Third')
      end

      it 'includes sample 1 information from the batch' do
        sample1_row = output.split("\r\n")[expected_phix_lines + expected_settings_lines]
        expect(sample1_row).to include('Sample_001,GTGCTGTC,CGTCGTCC,1,42') # sample_name,tag1,tag2,lane_number,study_id
      end

      it 'includes sample 2 information from the batch' do
        sample2_row = output.split("\r\n")[expected_phix_lines + expected_settings_lines + 1]
        expect(sample2_row).to include('Sample_002,TTTCCCG,CCCTTTG,2,42') # sample_name,tag1,tag2,lane_number,study_id
      end

      it 'produces the correct number of lines' do
        expected_sample_lines = 2 # comment + 2 sample rows from mocked batch
        expect(output.split("\r\n").size).to eq(expected_settings_lines + expected_phix_lines + expected_sample_lines)
      end
    end

    context 'with failed requests' do
      let(:request2) { instance_double(Request, target_asset: target_asset2, position: 2, failed?: true) }

      it 'excludes samples from failed requests' do
        expect(output).not_to include('Sample_002')
      end

      it 'produces the correct number of lines' do
        expected_sample_lines = 1 # comment + 1 sample row from mocked batch
        expect(output.split("\r\n").size).to eq(expected_settings_lines + expected_phix_lines + expected_sample_lines)
      end
    end

    context 'when same samples used in both lines' do
      let(:target_asset2) { instance_double(Receptacle, aliquots: [aliquot]) }

      it 'produces one row while specifying both lines' do
        sample1_row = output.split("\r\n")[expected_phix_lines + expected_settings_lines]
        expect(sample1_row).to include('Sample_001')
        expect(sample1_row).to include('1+2') # lane number should be '1+2' for both lanes
      end

      it 'produces the correct number of lines' do
        expected_sample_lines = 1 # comment + 1 sample row from mocked batch
        expect(output.split("\r\n").size).to eq(expected_settings_lines + expected_phix_lines + expected_sample_lines)
      end
    end

    context 'with same sample that is been sequencing under different studies' do
      let(:aliquot2) do
        instance_double(
          Aliquot,
          sample: sample,
          tag: instance_double(Tag, oligo: 'GTGCTGTC'),
          tag2: instance_double(Tag, oligo: 'CGTCGTCC'),
          study: study2
        )
      end
      let(:target_asset2) { instance_double(Receptacle, aliquots: [aliquot2]) }

      it 'produces one row while specifying both lines' do
        sample1_row = output.split("\r\n")[expected_phix_lines + expected_settings_lines]
        expect(sample1_row).to include('Sample_001,GTGCTGTC,CGTCGTCC,1,42')
        sample2_row = output.split("\r\n")[expected_phix_lines + expected_settings_lines + 1]
        expect(sample2_row).to include('Sample_001,GTGCTGTC,CGTCGTCC,2,55')
      end

      it 'produces the correct number of lines' do
        expected_sample_lines = 2 # comment + 1 sample row from mocked batch
        expect(output.split("\r\n").size).to eq(expected_settings_lines + expected_phix_lines + expected_sample_lines)
      end
    end

    context 'when sample indexes are 8 bp long' do
      it 'truncates PhiX control indexes to match the sample index length (8 bp)' do
        phix1_row = output.split("\r\n")[expected_settings_lines + 2]
        expect(phix1_row).to eq('PhiX_Third,ATGTCGCT,CTAGCTCG,1+2,')
        index1, index2 = phix1_row.split(',')[1..2]
        expect(index1.length).to eq(8)
        expect(index2.length).to eq(8)
      end
    end

    context 'when samples do not have tags' do
      let(:aliquot2) do
        instance_double(
          Aliquot,
          sample: sample2,
          tag: nil,
          tag2: nil,
          study: study2
        )
      end
      let(:aliquot) do
        instance_double(Aliquot,
                        sample: sample,
                        tag: nil,
                        tag2: nil,
                        study: study)
      end

      it 'removes the phix control tags' do
        phix1_row = output.split("\r\n")[expected_settings_lines + 2]
        expect(phix1_row).to eq('PhiX_Third') # No tags for PhiX control
      end
    end

    context 'when samples have different tag lengths (mix of 8bp and 10bp)' do
      let(:aliquot2) do
        instance_double(
          Aliquot,
          sample: sample2,
          tag: instance_double(Tag, oligo: 'GTGCTGTCAA'), # 10 bp tags
          tag2: instance_double(Tag, oligo: 'CGTCGTCCTT'),
          study: study2
        )
      end
      let(:aliquot) do
        instance_double(Aliquot,
                        sample: sample,
                        tag: instance_double(Tag, oligo: 'GTGCTGTC'), # 8 bp tags
                        tag2: instance_double(Tag, oligo: 'CGTCGTCC'),
                        study: study)
      end

      it 'matches the PhiX control tag with the longest sample tag' do
        phix1_row = output.split("\r\n")[expected_settings_lines + 2]
        expect(phix1_row).to eq('PhiX_Third,ATGTCGCTAG,CTAGCTCGTA,1+2,') # 10 bp tags
      end
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
