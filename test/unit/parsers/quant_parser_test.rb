require './test/test_helper'
require 'csv'

class QuantParserTest < ActiveSupport::TestCase
  def read_file(filename)
    content = nil
    File.open(filename, 'r') do |fd|
      content = fd.read
    end
    content
  end

  context 'Parser' do
    context 'With a valid csv file' do
      setup do
        @filename = Rails.root.to_s + '/test/data/quant_test.csv'
        @content = read_file @filename

        # We WANT to be using this encoding here. So if this line starts failing, fix the encoding in
        # the actual file.
        @csv = CSV.parse(@content.force_encoding('iso-8859-1'))
      end

      should 'return a QuantParser' do
        assert Parsers.parser_for(@filename, nil, @content).is_a?(Parsers::QuantParser)
      end

      context 'processing the file' do
        setup do
          @parser = Parsers.parser_for(@filename, nil, @content)
          @plate = create :plate, well_count: 18
          @default_conc = @plate.wells.first.get_concentration
          @plate.update_qc_values_with_parser(@parser)
          @wells = @plate.reload.wells.index_by(&:map_description)
        end

        should 'update well attributes with the file contents' do
          [['A1', 35, 7.5],
           ['A2', 56, 8.1],
           ['A3', 89, 4.3]].each do |location, concentration, _rin|
            assert_equal concentration, @wells[location].get_concentration
          end
        end
        should 'not update attributes for lines without content' do
          assert_equal @default_conc, @wells['B1'].get_concentration
          assert_equal @default_conc, @wells['B2'].get_concentration
          assert_equal @default_conc, @wells['B3'].get_concentration
        end
      end

      context 'processing the file on a working dilution' do
        setup do
          @filename = Rails.root.join('test', 'data', 'complete_quant_test.csv').to_s
          @content = read_file @filename
          @parser = Parsers.parser_for(@filename, nil, @content)
          @plate = create :working_dilution_plate, well_count: 18, plate_metadata_attributes: { dilution_factor: 10 }
          @parent = create :plate, well_count: 18
          @plate.parents << @parent
          @default_conc = @plate.wells.reload.first.get_concentration
          @plate.update_qc_values_with_parser(@parser)
          @wells = @plate.wells.reload.index_by(&:map_description)
          @parent_wells = @parent.wells.reload.index_by(&:map_description)
        end

        should 'update well attributes with the file contents' do
          [['A1', 35, 7.5],
           ['A2', 56, 8.1],
           ['A3', 89, 4.3]].each do |location, concentration, _rin|
            assert_equal concentration, @wells[location].get_concentration
          end
        end
        should 'not update attributes for lines without content' do
          assert_equal @default_conc, @wells['B1'].get_concentration
          assert_equal @default_conc, @wells['B2'].get_concentration
          assert_equal @default_conc, @wells['B3'].get_concentration
        end
        should 'update parent well attributes with adjusted concentration contents' do
          [['A1', 350, 7.5],
           ['A2', 560, 8.1],
           ['A3', 890, 4.3]].each do |location, concentration, rin|
            assert_equal concentration, @parent_wells[location].get_concentration
            assert_equal rin, @parent_wells[location].get_rin
          end
        end
        should 'not update patent attributes for lines without content' do
          assert_equal @default_conc, @parent_wells['B1'].get_concentration
          assert_equal @default_conc, @parent_wells['B2'].get_concentration
          assert_equal @default_conc, @parent_wells['B3'].get_concentration
        end
      end
    end

    context 'With an actual example csv file' do
      setup do
        @filename = Rails.root.to_s + '/test/data/quant_test_example.csv'
        @content = read_file @filename

        # We WANT to be using this encoding here. So if this line starts failing, fix the encoding in
        # the actual file.
        @csv = CSV.parse(@content.force_encoding('iso-8859-1'))
      end

      should 'return a QuantParser' do
        assert Parsers.parser_for(@filename, nil, @content).is_a?(Parsers::QuantParser)
      end

      context 'processing the file' do
        setup do
          @parser = Parsers.parser_for(@filename, nil, @content)
          @plate = create :plate, well_count: 18
          @default_conc = @plate.wells.first.get_concentration
          @plate.update_qc_values_with_parser(@parser)
          @wells = @plate.wells.reload.index_by(&:map_description)
        end

        should 'update well attributes with the file contents' do
          [['A1', 134.47, 7.5],
           ['A2', 81.96, 8.1],
           ['A3', 36.76, 4.3]].each do |location, concentration, _rin|
            assert_equal concentration, @wells[location].get_concentration
          end
        end
      end
    end

    context 'with an invalid csv file' do
      setup do
        @filename = Rails.root.to_s + '/test/data/invalid_quant_test.csv'
        @content = read_file @filename
        @csv = CSV.parse(@content)
      end

      should 'detect that the format is not correct' do
        refute Parsers::QuantParser.parses?(@csv)
      end
    end
  end
end
