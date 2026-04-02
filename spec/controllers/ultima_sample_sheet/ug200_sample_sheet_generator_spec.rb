# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UltimaSampleSheet::UG200SampleSheetGenerator do
  # First oligo sequences for the two UG200 tag groups.
  let(:plate1_first_oligo) { 'CTGCACATTGTAGAT' }
  let(:plate2_first_oligo) { 'CATCATGCTCCGCTGAT' }
  let(:tag_group1_name) { 'Ultima P3' }
  let(:tag_group2_name) { 'UG-RD-1916 (Solaris 2.0 V1 PCR-Free Adapters for Ultima Genomics P4)' }

  # Eagerly create tag groups and tags to get consistent IDs.
  let!(:tag_group1) do
    create(:tag_group_with_tags, tag_count: 96, name: tag_group1_name).tap do |tg|
      # To test Z0001 matching with the oligo sequence.
      tg.tags.first.update!(oligo: plate1_first_oligo)
    end
  end

  let!(:tag_group2) do
    create(:tag_group_with_tags, tag_count: 96, name: tag_group2_name).tap do |tg|
      # To test Z0097 matching with the oligo sequence.
      tg.tags.first.update!(oligo: plate2_first_oligo)
    end
  end
  let(:tag_groups) { [tag_group1, tag_group2] }

  let(:request_type) { create(:ultima_sequencing) }
  let(:pipeline) { create(:ultima_sequencing_pipeline, request_types: [request_type]) }
  let(:batch) { create(:ultima_sequencing_batch, pipeline:, requests:) }
  let(:requests) { [request1, request2] }
  let(:request1) { create(:ultima_sequencing_request, asset: tube1.receptacle, request_type: request_type) }
  let(:request2) { create(:ultima_sequencing_request, asset: tube2.receptacle, request_type: request_type) }

  # Eagerly create tubes with aliquots to get consistent IDs.
  let!(:tube1) do
    receptacle = create(:receptacle)
    create(:aliquot, tag: tag_group1.tags.first, receptacle: receptacle)
    tube = create(:multiplexed_library_tube, receptacle:)
    create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
    tube
  end

  let!(:tube2) do
    receptacle = create(:receptacle)
    create(:aliquot, tag: tag_group2.tags.first, receptacle: receptacle)
    tube = create(:multiplexed_library_tube, receptacle:)
    create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
    tube
  end

  # Expected mapping of tag groups to their respective 1-based plate numbers.
  let(:tag_group_index_map) { { tag_group1 => 1, tag_group2 => 2 } }

  # Expected mapping of tags to their respective 1-based index numbers.
  let(:tag_index_map) do
    tags = tag_groups.flat_map { |tg| tg.tags.sort_by(&:map_id) }
    tags.each_with_index.to_h { |tag, i| [tag, i + 1] }
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

    it 'uses UG200 tag group mapping config' do
      expect(generator.tag_groups_config).to eq(tag_group1_name => 1, tag_group2_name => 2)
    end

    it 'maps the first plate sample indexes and plate number', :aggregate_failures do
      expect(csv1[9][2]).to eq('Z0001')
      expect(csv1[9][3]).to eq(plate1_first_oligo)
      expect(csv1[9][4]).to eq(tag_group_index_map[tag_group1].to_s)
      expect(csv1[9][2]).to eq(format('Z%04d', tag_index_map[tag_group1.tags.first]))
    end

    it 'maps the second plate sample indexes and plate number', :aggregate_failures do
      expect(csv2[9][2]).to eq('Z0097')
      expect(csv2[9][3]).to eq(plate2_first_oligo)
      expect(csv2[9][4]).to eq(tag_group_index_map[tag_group2].to_s)
      expect(csv2[9][2]).to eq(format('Z%04d', tag_index_map[tag_group2.tags.first]))
    end
  end
end
