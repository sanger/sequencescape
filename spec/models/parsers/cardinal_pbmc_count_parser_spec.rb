# frozen_string_literal: true

require 'rails_helper'

# Well Name	Live Count	Live Cells/mL	Live Mean Size	Viability	Dead Count
# Dead Cells/mL	Dead Mean Size	Total Count	Total Cells/mL
# Total Mean Size	Note:	Errors:

# DN871908M:A1	1074	2030000	9.35	75.00%	361	682000	2.36	1435	2710000	9.36
# DN871908M:B1	1074	2030000	8.84	76.00%	341	644000	2.34	1415	2670000	9.06
# DN871908M:C1	1218	2300000	8.81	75.00%	396	748000	2.21	1614	3050000	8.86
# DN871908M:D1	1111	2100000	9.23	75.00%	371	700000	2.38	1482	2800000	9.31
# DN871908M:E1	1208	2280000	8.77	75.00%	396	748000	2.3	1604	3030000	8.9
# DN871908M:F1	1120	2110000	8.74	75.00%	377	712000	2.34	1497	2820000	8.88
# DN871908M:G1	1177	2220000	8.79	76.00%	374	705000	2.14	1551	2930000	8.8
# DN871908M:H1	1029	1940000	8.37	74.00%	357	675000	2.35	1386	2610000	8.57

def read_file(filename)
  File.read(filename)
end

RSpec.describe Parsers::CardinalPbmcCountParser do
  it 'will have an assay type' do
    expect(described_class.assay_type).to eq('Cardinal_PBMC_Count')
  end

  it 'will have an assay version' do
    expect(described_class.assay_version).to eq('v1.0')
  end

  context 'when a file is parsed' do
    let(:filename) { Rails.root.join('spec/data/parsers/cardinal_pbmc_count.csv') }
    let(:content) { read_file(filename) }
    let(:csv) { CSV.parse(content) }
    let(:parser) { described_class.new(csv) }

    it 'will return the correct parser' do
      expect(Parsers.parser_for('cardinal_pbmc_count.csv', nil, content)).to be_a(described_class)
    end

    it 'will have some content' do
      expect(parser.content).to eq(csv)
    end

    context 'when parsing rows' do
      let(:rows) { parser.rows }

      it 'will have the correct number of rows' do
        expect(rows.length).to eq(8)
      end

      it 'will have the correct csv for well A1' do
        row = rows[0]
        expect(row[0]).to eq('DN871908M:A1')
        expect(row[2]).to eq('2030000')
        expect(row[4]).to eq('75.00%')
        expect(row[9]).to eq('2710000')
      end

      it 'will have the correct csv for well H1' do
        row = rows[7]
        expect(row[0]).to eq('DN871908M:H1')
        expect(row[2]).to eq('1940000')
        expect(row[4]).to eq('74.00%')
        expect(row[9]).to eq('2610000')
      end
    end

    context 'when formatting into qc data' do
      let(:qc_data) { parser.qc_data }

      it 'will have the correct number of values' do
        expect(qc_data.values.length).to eq(8)
      end

      it 'will have the correct data for well A1' do
        row = qc_data['A1']
        expect(row[:live_cell_count]).to eq(Unit.new('2030000', 'cells'))
        expect(row[:viability]).to eq(Unit.new('75.00', '%'))
        expect(row[:total_cell_count]).to eq(Unit.new('2710000', 'cells'))
      end

      it 'will have the correct data for well H1' do
        row = qc_data['H1']
        expect(row[:live_cell_count]).to eq(Unit.new('1940000', 'cells'))
        expect(row[:viability]).to eq(Unit.new('74.00', '%'))
        expect(row[:total_cell_count]).to eq(Unit.new('2610000', 'cells'))
      end
    end
  end

  context 'when the file has blank rows' do
    # this file has 1 row and 23 blank rows
    let(:filename) { Rails.root.join('spec/data/parsers/cardinal_pbmc_count_blank_rows.csv') }
    let(:content) { read_file(filename) }
    let(:csv) { CSV.parse(content) }
    let(:parser) { described_class.new(csv) }

    it 'will return the correct parser' do
      expect(Parsers.parser_for('cardinal_pbmc_count.csv', nil, content)).to be_a(described_class)
    end

    it 'will have some content' do
      expect(parser.content).to eq(csv)
    end

    it 'will have some qc data' do
      expect(parser.qc_data.values.length).to eq(1)
    end
  end

  context 'when a row has no cells' do
    # this file has 1 normal row, and a couple of rows with 0 live cells, and NaN viability
    let(:filename) { Rails.root.join('spec/data/parsers/cardinal_pbmc_count_no_cells.csv') }
    let(:content) { read_file(filename) }
    let(:csv) { CSV.parse(content) }
    let(:parser) { described_class.new(csv) }

    it 'will have three qc data entries - one for each row in the file' do
      expect(parser.qc_data.values.length).to eq(3)
    end

    it 'will have cell count and viability metrics for the normal row' do
      expect(parser.qc_data['A4'].keys).to eq(%i[live_cell_count total_cell_count viability])
    end

    it 'will have just cell count for the rows with 0 cells' do
      expect(parser.qc_data['A5'].keys).to eq(%i[live_cell_count total_cell_count])
      expect(parser.qc_data['E5'].keys).to eq(%i[live_cell_count total_cell_count])
      expect(parser.qc_data['E5'][:live_cell_count].zero?).to be(true)
      expect(parser.qc_data['E5'][:total_cell_count].zero?).to be(true)
    end
  end

  context 'when updating qc results' do
    let(:plate) { create(:plate_with_empty_wells, well_count: 96) }
    let(:filename) { Rails.root.join('spec/data/parsers/cardinal_pbmc_count.csv') }
    let(:content) { read_file(filename) }
    let(:csv) { CSV.parse(content) }
    let(:parser) { described_class.new(csv) }

    context 'when creating some qc results' do
      before { plate.update_qc_values_with_parser(parser) }

      it 'will have the correct number of results' do
        expect(QcResult.count).to eq(24)
      end

      it 'will create the qc results for well A1' do
        well = plate.wells.located_at('A1').first
        qc_results = QcResult.where(asset_id: well.id)

        qc_result = qc_results.find_by(key: 'viability')

        expect(qc_result.value).to eq('75')
        expect(qc_result.units).to eq('%')
        expect(qc_result.assay_type).to eq('Cardinal_PBMC_Count')
        expect(qc_result.assay_version).to eq('v1.0')

        qc_result = qc_results.find_by(key: 'live_cell_count')

        expect(qc_result.value).to eq('2030000')
        expect(qc_result.units).to eq('cells/ml')
        expect(qc_result.assay_type).to eq('Cardinal_PBMC_Count')
        expect(qc_result.assay_version).to eq('v1.0')

        qc_result = qc_results.find_by(key: 'total_cell_count')

        expect(qc_result.value).to eq('2710000')
        expect(qc_result.units).to eq('cells/ml')
        expect(qc_result.assay_type).to eq('Cardinal_PBMC_Count')
        expect(qc_result.assay_version).to eq('v1.0')
      end

      it 'will create the qc results for well H1' do
        well = plate.wells.located_at('H1').first
        qc_results = QcResult.where(asset_id: well.id)

        qc_result = qc_results.find_by(key: 'viability')

        expect(qc_result.value).to eq('74')
        expect(qc_result.units).to eq('%')

        qc_result = qc_results.find_by(key: 'live_cell_count')

        expect(qc_result.value).to eq('1940000')
        expect(qc_result.units).to eq('cells/ml')

        qc_result = qc_results.find_by(key: 'total_cell_count')

        expect(qc_result.value).to eq('2610000')
        expect(qc_result.units).to eq('cells/ml')
      end
    end
  end
end
