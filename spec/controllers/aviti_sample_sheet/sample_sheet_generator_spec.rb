# frozen_string_literal: true

require 'rails_helper'
# rubocop:disable RSpec/VerifiedDoubles
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

  let(:asset) { instance_double(Receptacle, aliquots: [aliquot]) }
  let(:asset2) { instance_double(Receptacle, aliquots: [aliquot2]) }

  let(:request) { instance_double(Request, asset: asset, position: 1, failed?: false) }
  let(:request2) { instance_double(Request, asset: asset2, position: 2, failed?: false) }

  let(:batch) { instance_double(Batch, requests: [request, request2]) }

  describe '.generate' do
    subject(:output) { described_class.generate(batch) }

    let(:task) { double('Task', name: described_class::Generator::PHIX_TYPE_TASK_NAME) }
    let(:expected_settings_lines) { 7 } # [SETTINGS], header, comment, 4 adapter rows
    let(:expected_phix_lines) { 6 }     # [SAMPLES], header, 4 phiX samples

    before do
      allow(batch).to receive(:tasks).and_return([task])
      allow(task).to receive(:descriptors_for).and_return([])
    end

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
      let(:request2) { instance_double(Request, asset: asset2, position: 2, failed?: true) }

      it 'excludes samples from failed requests' do
        expect(output).not_to include('Sample_002')
      end

      it 'produces the correct number of lines' do
        expected_sample_lines = 1 # comment + 1 sample row from mocked batch
        expect(output.split("\r\n").size).to eq(expected_settings_lines + expected_phix_lines + expected_sample_lines)
      end
    end

    context 'when same samples used in both lines' do
      let(:asset2) { instance_double(Receptacle, aliquots: [aliquot]) }

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
      let(:asset2) { instance_double(Receptacle, aliquots: [aliquot2]) }

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

  describe 'PhiX type selection' do
    let(:task_name) { described_class::Generator::PHIX_TYPE_TASK_NAME }
    let(:descriptor_name) { described_class::Generator::PHIX_TYPE_DESCRIPTOR_NAME }
    let(:element_phix) { described_class::Generator::ELEMENT_PHIX_TYPE }
    let(:comp_phix) { described_class::Generator::COMP_PHIX_TYPE }
    let(:element_phix_section) { described_class::Generator::ELEMENT_PHIX_SECTION }
    let(:comp_phix_section) { described_class::Generator::COMP_PHIX_SECTION }

    let(:batch) do
      create(:batch, pipeline:).tap { |b| b.requests << request1 << request2 }
    end
    let(:request_type) { create(:element_aviti_sequencing) }
    let(:pipeline) { create(:element_aviti_sequencing_pipeline, workflow: workflow, request_types: [request_type]) }
    let(:workflow) { create(:lab_workflow_for_pipeline, tasks: [task]) }
    let(:task) { create(:set_descriptors_task, name: task_name, descriptors: [desc]) }
    let(:desc) do
      create(:descriptor,
             name: descriptor_name,
             selection: { element_phix => element_phix, comp_phix => comp_phix },
             kind: 'Selection',
             required: true)
    end
    let(:requests) { [request1, request2] }
    let(:request1) { create(:element_aviti_sequencing_request, asset: tube1.receptacle) }
    let(:request2) { create(:element_aviti_sequencing_request, asset: tube2.receptacle) }

    let(:study) { create(:study) }

    # samples for request1
    let(:samples1_section) do
      [
        ['sample_1_SQPD-9010_A1',	'CCGCGGTT',	'AGCGCTAG',	1,	study.id],
        ['sample_1_SQPD-9010_B1',	'TTATAACC',	'GATATCGA',	1,	study.id],
        ['sample_1_SQPD-9010_C1',	'GGACTTGG',	'CGCAGACG',	1,	study.id]
      ]
    end
    # samples for request2
    let(:samples2_section) do
      [
        ['sample_2_SQPD-9030_A1',	'CCGCGGTT',	'AGCGCTAG',	2,	study.id],
        ['sample_2_SQPD-9030_B1',	'TTATAACC',	'GATATCGA',	2,	study.id],
        ['sample_2_SQPD-9030_C1',	'GGACTTGG',	'CGCAGACG',	2,	study.id]
      ]
    end

    let(:tube1) { create_tube(samples1_section) }
    let(:tube2) { create_tube(samples2_section) }
    let(:generator) { described_class::Generator.new(batch) }

    # Helper to create a tube with aliquots for the given section.
    # @param section [Array<Array>] a list of expected sample rows
    # @return [Tube] the tube with associated aliquots, samples, tags, and study.
    def create_tube(section)
      receptacle = create(:receptacle)
      section.each do |sample_name, index1, index2, _lane, _study_id|
        sample = create(:sample, name: sample_name)
        tag = create(:tag, oligo: index1)
        tag2 = create(:tag, oligo: index2)
        create(:aliquot, sample:, tag:, tag2:, study:, receptacle:)
      end

      tube = create(:multiplexed_library_tube, receptacle:)
      create(:event, content: Time.zone.today.to_s, message: 'scanned in',
                     family: 'scanned_into_lab', eventful: tube)
      tube
    end

    # Truncates the PhiX control indexes in the given section to length 8.
    # @param section [Array<Array>] a list of PhiX rows
    # #@return [Array<Array>] the section with truncated indexes
    def truncate_indexes(section)
      section.map do |row|
        row = row.dup
        row[1] = row[1][0, 8] if row[1] # 8 elements starting with 0
        row[2] = row[2][0, 8] if row[2]
        row
      end
    end

    # Element PhiX behaviour.
    shared_examples 'generates Element PhiX section' do
      it 'generates Element PhiX section' do
        csv = CSV.parse(generator.generate)
        phix_section = csv[9, 4] # zero-based
        expect(phix_section).to eq(truncate_indexes(element_phix_section))
      end
    end

    # Comp PhiX behaviour.
    shared_examples 'generates Comp PhiX section' do
      it 'generates Comp PhiX section' do
        csv = CSV.parse(generator.generate)
        phix_section = csv[9, 1] # zero-based
        expect(phix_section).to eq(truncate_indexes(comp_phix_section))
      end
    end

    context 'when the loading task is missing' do
      before { allow(batch).to receive(:tasks).and_return([]) }

      it 'defaults to Element PhiX' do
        expect(generator.send(:selected_phix_type)).to eq element_phix
      end
    end

    context 'when the descriptor is missing' do
      before do
        allow(task).to receive(:descriptors_for).and_return([])
      end

      it 'defaults to Element PhiX' do
        expect(generator.send(:selected_phix_type)).to eq element_phix
      end

      it_behaves_like 'generates Element PhiX section'
    end

    context 'when the descriptor is Element PhiX' do
      before do
        create(:lab_event, {
                 description: task_name,
                 descriptors: { descriptor_name => element_phix },
                 eventful: request1,
                 batch: batch
               })
      end

      it 'returns Element PhiX' do
        expect(generator.send(:selected_phix_type)).to eq element_phix
      end

      it_behaves_like 'generates Element PhiX section'
    end

    context 'when the descriptor is Comp PhiX' do
      before do
        create(:lab_event, {
                 description: task_name,
                 descriptors: { descriptor_name => comp_phix },
                 eventful: request1,
                 batch: batch
               })
      end

      it 'returns Comp PhiX' do
        expect(generator.send(:selected_phix_type)).to eq comp_phix
      end

      it_behaves_like 'generates Comp PhiX section'
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
