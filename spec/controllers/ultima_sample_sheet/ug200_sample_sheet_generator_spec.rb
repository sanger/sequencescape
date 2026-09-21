# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UltimaSampleSheet::UG200SampleSheetGenerator do
  # First oligo sequences for the two UG200 tag groups.
  let(:plate3_first_oligo) { 'CTGCACATTGTAGAT' } # Z0193
  let(:plate4_first_oligo) { 'CATCATGCTCCGCTGAT' } # Z0289
  let(:tag_group3_name) { 'Ultima P3' }
  let(:tag_group4_name) { 'UG-RD-1916 (Solaris 2.0 V1 PCR-Free Adapters for Ultima Genomics P4)' }

  # Eagerly create tag groups and tags to get consistent IDs.
  let!(:tag_group3) do
    create(:tag_group_with_tags, tag_count: 96, name: tag_group3_name).tap do |tg|
      # To test Z0193 matching with the oligo sequence.
      tg.tags.first.update!(oligo: plate3_first_oligo)
    end
  end

  let!(:tag_group4) do
    create(:tag_group_with_tags, tag_count: 96, name: tag_group4_name).tap do |tg|
      # To test Z0289 matching with the oligo sequence.
      tg.tags.first.update!(oligo: plate4_first_oligo)
    end
  end
  let(:tag_groups) { [tag_group3, tag_group4] }

  let(:request_type) { create(:ultima_ug200_sequencing) }
  let(:pipeline) { create(:ultima_ug200_sequencing_pipeline, request_types: [request_type]) }
  let(:batch) { create(:ultima_sequencing_batch, pipeline:, requests:) }
  let(:requests) { [request1, request2] }
  let(:request1) { create(:ultima_sequencing_request, asset: tube1.receptacle, request_type: request_type) }
  let(:request2) { create(:ultima_sequencing_request, asset: tube2.receptacle, request_type: request_type) }

  # Eagerly create tubes with aliquots to get consistent IDs.
  let(:library_type) { 'Standard' }

  let!(:tube1) do
    receptacle = create(:receptacle)
    create(:aliquot, tag: tag_group3.tags.first, receptacle: receptacle, library_type: library_type)
    tube = create(:multiplexed_library_tube, receptacle:)
    create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
    tube
  end

  let!(:tube2) do
    receptacle = create(:receptacle)
    create(:aliquot, tag: tag_group4.tags.first, receptacle: receptacle, library_type: library_type)
    tube = create(:multiplexed_library_tube, receptacle:)
    create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
    tube
  end

  # Expected mapping of tag groups to their respective 1-based plate numbers.
  let(:tag_group_index_map) { { tag_group3 => 3, tag_group4 => 4 } }

  # Expected mapping of tags to their respective 1-based index numbers.
  # Mirrors the generator's tag_index_map: config-value-based offsets.
  let(:tag_index_map) do
    tag_groups.each_with_object({}) do |tg, map|
      start_index = generator.ultima_tag_groups_config[tg.name][:z_start]
      tg.tags.sort_by(&:map_id).each_with_index { |tag, i| map[tag] = start_index + i }
    end
  end

  context 'with csv output' do
    subject(:generator) { described_class::Generator.new(batch) }

    # Parse the generated CSV for the tubes into rows and columns.
    let(:csv1) { CSV.parse(generator.csv_string(request1), row_sep: "\r\n", nil_value: '') }
    let(:csv2) { CSV.parse(generator.csv_string(request2), row_sep: "\r\n", nil_value: '') }

    it 'generates UG200 global section', :aggregate_failures do
      expect(generator.global_headers_config).to eq(['Application'])
      expect(csv1[3].compact_blank).to eq(generator.global_title_config)
      expect(csv1[4].compact_blank).to eq(['Application'])
      expect(csv1[5].compact_blank).to eq(['WGS Native'])
    end

    context 'with amplified libraries' do
      let(:library_type) { 'Ultima High Throughput PCR Amplified 96' }

      it 'generates amplified application values', :aggregate_failures do
        expect(csv1[5].compact_blank).to eq(['WGS Native Amplified'])
        expect(csv1[9][6]).to eq('native')
      end
    end

    it 'uses UG200 tag group mapping config' do
      expect(generator.ultima_tag_groups_config.slice(tag_group3_name, tag_group4_name)).to eq(
        tag_group3_name => { plate_num: 3, z_start: 193 },
        tag_group4_name => { plate_num: 4, z_start: 289 }
      )
    end

    it 'maps the first plate sample indexes and plate number', :aggregate_failures do
      expect(csv1[9][2]).to eq('Z0193')
      expect(csv1[9][3]).to eq(plate3_first_oligo)
      expect(csv1[9][4]).to eq(tag_group_index_map[tag_group3].to_s)
      expect(csv1[9][2]).to eq(format('Z%04d', tag_index_map[tag_group3.tags.first]))
    end

    it 'maps the second plate sample indexes and plate number', :aggregate_failures do
      expect(csv2[9][2]).to eq('Z0289')
      expect(csv2[9][3]).to eq(plate4_first_oligo)
      expect(csv2[9][4]).to eq(tag_group_index_map[tag_group4].to_s)
      expect(csv2[9][2]).to eq(format('Z%04d', tag_index_map[tag_group4.tags.first]))
    end
  end

  context 'with the Solaris P1 tag group alongside the existing P4' do
    subject(:generator) { described_class::Generator.new(batch) }

    let(:solaris_p1_first_oligo) { 'CAGCTCGAATGCGAT' } # Z0001, same range as 'Ultima P1'
    let(:solaris_p1_tag_group_name) { 'UG-RD-1940 (Solaris 2.0 PCR-Free Adapters for Ultima Genomics P1)' }

    let!(:solaris_p1_tag_group) do
      create(:tag_group_with_tags, tag_count: 96, name: solaris_p1_tag_group_name).tap do |tg|
        # To test Z0001 matching with the oligo sequence.
        tg.tags.first.update!(oligo: solaris_p1_first_oligo)
      end
    end
    let(:request_type) { create(:ultima_ug200_sequencing) }
    let(:pipeline) { create(:ultima_ug200_sequencing_pipeline, request_types: [request_type]) }
    let(:batch) { create(:ultima_sequencing_batch, pipeline: pipeline, requests: [request1, request2]) }
    let(:request1) { create(:ultima_sequencing_request, asset: tube1.receptacle, request_type: request_type) }
    let(:request2) { create(:ultima_sequencing_request, asset: tube2.receptacle, request_type: request_type) }
    let(:library_type) { 'Standard' }
    let(:csv1) { CSV.parse(generator.csv_string(request1), row_sep: "\r\n", nil_value: '') }
    let(:csv2) { CSV.parse(generator.csv_string(request2), row_sep: "\r\n", nil_value: '') }

    # Tube 1 uses the new Solaris P1 tag group.
    let!(:tube1) do
      receptacle = create(:receptacle)
      create(:aliquot, tag: solaris_p1_tag_group.tags.first, receptacle: receptacle, library_type: library_type)
      tube = create(:multiplexed_library_tube, receptacle:)
      create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
      tube
    end

    # Tube 2 uses the existing P4 tag group (tag_group4, defined above), to
    # confirm the two tag groups don't clash when used in the same batch.
    let!(:tube2) do
      receptacle = create(:receptacle)
      create(:aliquot, tag: tag_group4.tags.first, receptacle: receptacle, library_type: library_type)
      tube = create(:multiplexed_library_tube, receptacle:)
      create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
      tube
    end

    it 'uses the same plate number and z_start as Ultima P1, leaving P4 unaffected' do
      expect(generator.ultima_tag_groups_config.slice(solaris_p1_tag_group_name, tag_group4_name)).to eq(
        solaris_p1_tag_group_name => { plate_num: 1, z_start: 1 },
        tag_group4_name => { plate_num: 4, z_start: (3 * 96) + 1 }
      )
    end

    it 'maps the Solaris P1 sample index, oligo sequence, and plate number', :aggregate_failures do
      expect(csv1[9][2]).to eq('Z0001')
      expect(csv1[9][3]).to eq(solaris_p1_first_oligo)
      expect(csv1[9][4]).to eq('1')
    end

    it 'still maps the existing P4 sample index, oligo sequence, and plate number', :aggregate_failures do
      expect(csv2[9][2]).to eq(format('Z%04d', (3 * 96) + 1))
      expect(csv2[9][3]).to eq(plate4_first_oligo)
      expect(csv2[9][4]).to eq('4')
    end
  end
end
