# frozen_string_literal: true

require 'rails_helper'

describe Robot::Generator::Beckman, type: :model do
  subject(:generator) { described_class.new(picking_data: data_object) }

  let(:expected_output) { expected_file.read }

  shared_examples 'a beckman file generation' do
    context 'when mapping wells from 1 96 well source plate to 1 96 well destination plate' do
      it 'returns a String object' do
        expect(generator.mapping).to be_a_kind_of(String)
      end

      it 'generates the expected output' do
        expect(generator.mapping).equal?(expected_output)
      end

      it 'contains column headers' do
        # rubocop:todo Layout/LineLength
        regex = /^SourcePlateID,SourceWellID,SourcePlateType,SourcePlateVolume,DestinationPlateID,DestinationWellID,DestinationPlateType,DestinationPlateVolume,WaterVolume/

        # rubocop:enable Layout/LineLength

        assert_match(regex, generator.mapping)
      end

      it 'contains source control plate rows' do
        # rubocop:todo Layout/LineLength
        regex = /(?:DN626424D,[A-P]\d*,ABgene_0800,[0-9]*+(\.[0-9]*),DN12345U,[A-P]\d*,Eppendorf Twin.Tec,[0-9]*+(\.[0-9]*),[0-9]*+(\.[0-9]*))/

        # rubocop:enable Layout/LineLength

        assert_match(regex, generator.mapping)
      end

      it 'contains source plate rows' do
        # rubocop:todo Layout/LineLength
        regex = /(?:10001,[A-P]\d*,KingFisher 96 2ml,[0-9]*+(\.[0-9]*),DN12345U,[A-P]\d*,Eppendorf Twin.Tec,[0-9]*+(\.[0-9]*),[0-9]*+(\.[0-9]*))/

        # rubocop:enable Layout/LineLength

        assert_match(regex, generator.mapping)
      end
    end

    context 'when passed invalid object' do
      it 'throws an ArgumentError' do
        expect { generator.mapping nil }.to raise_error(ArgumentError)
      end
    end
  end

  context 'when performing a cherrypick with a control and multiple sources' do
    let(:expected_file) { File.open('spec/data/beckman/standard_cherrypick.csv', 'rb') }
    let(:data_object) do
      {
        'source' => {
          'DN626424D' => {
            'name' => 'ABgene_0800',
            'plate_size' => 96
          },
          '10001' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10002' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10003' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10004' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10005' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10006' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10007' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10008' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10009' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10010' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10011' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10012' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          },
          '10013' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          }
        },
        'destination' => {
          'DN12345U' => {
            'name' => 'Eppendorf Twin.Tec',
            'plate_size' => 96,
            'mapping' => [
              { 'src_well' => %w[DN626424D A1], 'dst_well' => 'B12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[DN626424D H12], 'dst_well' => 'H12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 A1], 'dst_well' => 'A1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 E2], 'dst_well' => 'A9', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 C1], 'dst_well' => 'B5', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 F1], 'dst_well' => 'B9', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 E1], 'dst_well' => 'C5', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 G9], 'dst_well' => 'C9', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 G1], 'dst_well' => 'D5', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 H1], 'dst_well' => 'D9', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 A5], 'dst_well' => 'E1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 A4], 'dst_well' => 'E5', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 B1], 'dst_well' => 'F1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 C3], 'dst_well' => 'F5', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 C4], 'dst_well' => 'G1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 E9], 'dst_well' => 'G5', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 D12], 'dst_well' => 'H1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 A1], 'dst_well' => 'A4', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 E2], 'dst_well' => 'A12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 C1], 'dst_well' => 'B8', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 F1], 'dst_well' => 'H11', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 E1], 'dst_well' => 'C8', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 G4], 'dst_well' => 'C12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 G1], 'dst_well' => 'D8', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 A4], 'dst_well' => 'E8', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 B1], 'dst_well' => 'F4', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 C4], 'dst_well' => 'G4', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10010 D12], 'dst_well' => 'H4', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10011 H1], 'dst_well' => 'D12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 A4], 'dst_well' => 'A8', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 B1], 'dst_well' => 'B4', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 C4], 'dst_well' => 'C4', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 D12], 'dst_well' => 'D4', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 A1], 'dst_well' => 'E4', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 E2], 'dst_well' => 'E12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 C1], 'dst_well' => 'F8', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 F1], 'dst_well' => 'F12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 E1], 'dst_well' => 'G8', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10012 G1], 'dst_well' => 'H8', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10013 G1], 'dst_well' => 'G12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10002 A4], 'dst_well' => 'A5', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10002 B1], 'dst_well' => 'B1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10002 G1], 'dst_well' => 'H5', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 A1], 'dst_well' => 'A2', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 E6], 'dst_well' => 'A10', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 C1], 'dst_well' => 'B6', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 F6], 'dst_well' => 'B10', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 C4], 'dst_well' => 'C1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 E1], 'dst_well' => 'C6', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 G6], 'dst_well' => 'C10', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 D12], 'dst_well' => 'D1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 G1], 'dst_well' => 'D6', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 H11], 'dst_well' => 'D10', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 A3], 'dst_well' => 'E2', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 A4], 'dst_well' => 'E6', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 E2], 'dst_well' => 'E9', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 B1], 'dst_well' => 'F2', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 C9], 'dst_well' => 'F6', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 F1], 'dst_well' => 'F9', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 C4], 'dst_well' => 'G2', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 E12], 'dst_well' => 'G6', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 G1], 'dst_well' => 'G9', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 D11], 'dst_well' => 'H2', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 G9], 'dst_well' => 'H6', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10003 H1], 'dst_well' => 'H9', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 A1], 'dst_well' => 'A3', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 A4], 'dst_well' => 'A6', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 A6], 'dst_well' => 'A7', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 E5], 'dst_well' => 'A11', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 B1], 'dst_well' => 'B2', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 B12], 'dst_well' => 'B3', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 C1], 'dst_well' => 'B7', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 F3], 'dst_well' => 'B11', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 C4], 'dst_well' => 'C2', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 E1], 'dst_well' => 'C7', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 G8], 'dst_well' => 'C11', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 D12], 'dst_well' => 'D2', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 G2], 'dst_well' => 'D7', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 H10], 'dst_well' => 'D11', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 A5], 'dst_well' => 'E3', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 A12], 'dst_well' => 'E7', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 E2], 'dst_well' => 'E10', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 B11], 'dst_well' => 'F3', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 C12], 'dst_well' => 'F7', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 F1], 'dst_well' => 'F10', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 C6], 'dst_well' => 'G3', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 E12], 'dst_well' => 'G7', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 G1], 'dst_well' => 'G10', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 D11], 'dst_well' => 'H3', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 G10], 'dst_well' => 'H7', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10004 H1], 'dst_well' => 'H10', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10005 C4], 'dst_well' => 'C3', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10006 D12], 'dst_well' => 'D3', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10007 E2], 'dst_well' => 'E11', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10008 F1], 'dst_well' => 'F11', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10009 G1], 'dst_well' => 'G11', 'volume' => 10, 'buffer_volume' => 0.0 }
            ]
          }
        }
      }
    end

    it_behaves_like 'a beckman file generation'
  end

  context 'when performing a pooled cherrypick' do
    let(:expected_file) { File.open('spec/data/beckman/pooled_cherrypick.csv', 'rb') }
    let(:data_object) do
      {
        'source' => {
          'DN626424D' => {
            'name' => 'ABgene_0800',
            'plate_size' => 96
          },
          '10001' => {
            'name' => 'KingFisher 96 2ml',
            'plate_size' => 96
          }
        },
        'destination' => {
          'DN12345U' => {
            'name' => 'Eppendorf Twin.Tec',
            'plate_size' => 96,
            'mapping' => [
              { 'src_well' => %w[DN626424D A1], 'dst_well' => 'A12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[DN626424D H12], 'dst_well' => 'H12', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 A1], 'dst_well' => 'A1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 B1], 'dst_well' => 'A1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 C1], 'dst_well' => 'A1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 D1], 'dst_well' => 'A1', 'volume' => 10, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[10001 E1], 'dst_well' => 'A1', 'volume' => 10, 'buffer_volume' => 0.0 }
            ]
          }
        }
      }
    end

    it_behaves_like 'a beckman file generation'
  end
end
