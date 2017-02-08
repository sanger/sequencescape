# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class ManifestGeneratorTest < ActiveSupport::TestCase
  def remove_date(csv_string)
    csv_string.slice(0...(csv_string.index('Date:'))) + csv_string.slice(csv_string.index('Comments:')..csv_string.size)
  end

  headers =  "Institute Name:,WTSI,,,,,,,,,,,,,,,,\n"
  headers += "Comments:,STUDY\n"
  headers += 'Row,Institute Plate Label,Well,Is Control,Institute Sample Label,Species,Sex,'
  headers += 'Comments,Volume (ul),Conc (ng/ul),Extraction Method,WGA Method (if Applicable),'
  headers += "Mass of DNA used in WGA,Parent 1,Parent 2,Replicate(s),Tissue Source\n"

  context 'A manifest' do
    context '#remove_empty_quotes' do
      setup do
        @row_data = '!!,B,!!,A,!!,!!'
      end
      should 'remove exclaimation marks' do
        assert_equal ',B,,A,,', ManifestGenerator.remove_empty_quotes(@row_data)
      end
    end

    context '#create_header' do
      setup do
        @study = create :study
        @expected_header = [['Institute Name:', 'WTSI', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
         ['Date:', '2010-5-7'],
         ['Comments:', (@study.abbreviation).to_s],
         ['Row', 'Institute Plate Label', 'Well', 'Is Control', 'Institute Sample Label', 'Species',
          'Sex', 'Comments', 'Volume (ul)', 'Conc (ng/ul)', 'Extraction Method', 'WGA Method (if Applicable)',
          'Mass of DNA used in WGA', 'Parent 1', 'Parent 2', 'Replicate(s)', 'Tissue Source']]
        @manifest_header = ManifestGenerator.create_header([], @study)
      end
      [0, 2, 3].each do |header_line_index|
        should "return correct header for line #{header_line_index}" do
          assert_equal @expected_header[header_line_index], @manifest_header[header_line_index]
        end
      end
    end

    context 'well_concentration' do
      setup do
        @well = create :well
      end
      context 'with set concentration' do
        setup do
          @well.set_concentration(567)
          @well.save
        end
        should 'return inputted concentrations' do
          concentration = ManifestGenerator.well_concentration(@well)
          assert_equal 567, concentration
          assert concentration.is_a?(Integer)
        end
      end
      context 'with no set concentration' do
        setup do
          @well.well_attribute.concentration = nil
          @well.well_attribute.save
        end
        should 'return default value' do
          concentration = ManifestGenerator.well_concentration(@well)
          assert_equal 50, concentration
          assert concentration.is_a?(Integer)
        end
      end
    end

    context 'well_volume' do
      setup do
        @well = create :well
      end
      context 'with set volume' do
        setup do
          @well.set_requested_volume(567)
          @well.save
        end
        should 'return inputted volume' do
          volume = ManifestGenerator.well_volume(@well)
          assert_equal 567, volume
          assert volume.is_a?(Integer)
        end
      end
      context 'with no set volume' do
        should 'return default value' do
          volume = ManifestGenerator.well_volume(@well)
          assert_equal 13, volume
          assert volume.is_a?(Integer)
        end
      end
    end

    context '#well_sample_species' do
      setup do
        @well = create :well
        @sample = create :sample
      end
      context 'with no sample' do
        should 'throw an exeption' do
          assert_raises StandardError do
            ManifestGenerator.well_sample_species(@well)
          end
        end
      end
      context 'with a sample' do
        setup do
          @well.aliquots.create!(sample: @sample)
        end
        context 'with no set species' do
          should 'return the default species' do
            assert_equal 'Homo sapiens', ManifestGenerator.well_sample_species(@well)
          end
        end
        context 'with species property set' do
          setup do
            @sample.sample_metadata.sample_common_name = 'Species 1'
            @sample.save
          end
          should 'return the species from the property' do
            assert_equal 'Species 1', ManifestGenerator.well_sample_species(@well)
          end
        end
      end
    end

    context '#well_sample_is_control' do
      setup do
        @well = create :well
        @sample = create :sample
      end
      context 'with no sample' do
        should 'throw an exeption' do
          assert_raises StandardError do
            ManifestGenerator.well_sample_is_control(@well)
          end
        end
      end
      context 'with a sample' do
        setup do
          @well.aliquots.create!(sample: @sample)
        end
        context 'and no external value set' do
          should 'return default value' do
            control = ManifestGenerator.well_sample_is_control(@well)
            assert_equal 0, control
            assert control.is_a?(Integer)
          end
        end
        context 'with external value set' do
          setup do
            @sample.update_attributes!(control: true)
          end
          should 'return external value' do
            control = ManifestGenerator.well_sample_is_control(@well)
            assert_equal 1, control
            assert control.is_a?(Integer)
          end
        end
      end
    end

    context '#well_sample_gender' do
      setup do
        @well = create :well
        @sample = create :sample
      end
      context 'with no sample' do
        should 'throw an exeption' do
          assert_raises StandardError do
            ManifestGenerator.well_sample_gender(@well)
          end
        end
      end
      context 'with a sample' do
        setup do
          @well.aliquots.create!(sample: @sample)
          @well.save
        end
        context 'and no external value set' do
          should 'return default value' do
            control = ManifestGenerator.well_sample_gender(@well)
            assert_equal 'U', control
            assert control.is_a?(String)
          end
        end
        context 'with external value set' do
          {
            'M' => 'Male',
            'F' => 'Female',
            'U' => ['not applicable', 'mixed', 'hermaphrodite', nil]
          }.each do |expected, genders|
            Array(genders).each do |gender|
              should "see #{gender.inspect} as #{expected.inspect}" do
                @sample.sample_metadata.update_attributes!(gender: gender)
                assert_equal(expected, ManifestGenerator.well_sample_gender(@well))
              end
            end
          end
        end
      end
    end

    context '#well_sample_parent' do
      ['mother', 'father'].each do |parent|
        context "for #{parent}" do
          setup do
            @well = create :well
            @sample = create :sample
          end
          context 'with no sample' do
            should 'throw an exeption' do
              assert_raises StandardError do
                ManifestGenerator.well_sample_parent(@well, parent)
              end
            end
          end
          context 'with a sample' do
            setup do
              @well.aliquots.create!(sample: @sample)
              @well.save
            end
            context 'and no external value set' do
              should 'return default value' do
                parent_value = ManifestGenerator.well_sample_parent(@well, parent)
                assert_nil parent_value
              end
            end
            context 'with external value set' do
              setup do
                @sample.sample_metadata.update_attributes!(parent => 2)
              end
              should 'return external value' do
                parent_value = ManifestGenerator.well_sample_parent(@well, parent)
                assert parent_value.is_a?(Integer), "#{parent.inspect} is not an integer (#{parent_value})"
              end
            end
          end
        end
      end
    end

    context '#well_map_description' do
      [['A1', 'A01'], ['C2', 'C02'], ['H12', 'H12'], ['G9', 'G09']].each do |input_map, expected_map|
        context "for #{input_map}" do
          setup do
            @well = create :well, map: Map.find_by(description: input_map, asset_size: 96)
            @description = ManifestGenerator.well_map_description(@well)
          end
          should "return expected description of #{expected_map}" do
            assert @description.is_a?(String)
            assert_equal expected_map, @description
          end
        end
      end
    end

    context '#generate_manifest_row' do
      setup do
        @well = create :well
        @sample = create :sample
        @plate_barcode = '141865'
        @plate_label = 'AAA'
      end
      context 'where well has no sample' do
        should 'throw an exeption' do
          assert_raises StandardError do
            ManifestGenerator.generate_manifest_row(@well, @plate_barcode, @plate_label)
          end
        end
      end
      context 'with rows from a real manifest' do
        [['WG0109325-DNA', 'A1', 0, '141865', 'MIG683233', 'Homo sapiens', 'female', 13, 50,
          'WG0109325-DNA,A01,0,141865_A01_MIG683233,Homo sapiens,F,,13,50,-,,0,,,,-'],
         ['WG0109326-DNA', 'G12', 0, '141864', 'MIG683178', 'Homo sapiens', 'male', 13, 50,
          'WG0109326-DNA,G12,0,141864_G12_MIG683178,Homo sapiens,M,,13,50,-,,0,,,,-'],
         ['WG0110521-DNA', 'D2', 0, '135653', 'ALSPAC09892966', 'Homo sapiens', 'male', 13, 50,
          'WG0110521-DNA,D02,0,135653_D02_ALSPAC09892966,Homo sapiens,M,,13,50,-,,0,,,,-'],
         ['WG0109379-DNA', 'F1', 0, '135649', 'Exo_2302555', 'Homo sapiens', 'female', 13, 50,
          'WG0109379-DNA,F01,0,135649_F01_Exo_2302555,Homo sapiens,F,,13,50,-,,0,,,,-'],
         ['WG0017826-DNA', 'C2', 0, '124189', 'MET_MAG954712', 'Homo sapiens', 'female', 13, 50,
          'WG0017826-DNA,C02,0,124189_C02_MET_MAG954712,Homo sapiens,F,,13,50,-,,0,,,,-'],
         ['WG0017827-DNA', 'F12', 0, '124188', 'WTCCCT480976', 'Homo sapiens', 'female', 30, 50,
          'WG0017827-DNA,F12,0,124188_F12_WTCCCT480976,Homo sapiens,F,,30,50,-,,0,,,,-'],
         ['WG0011534-DNA', 'A10', 0, '122849', 'MET_T2D974341', 'Homo sapiens', 'female', 30, 50,
          'WG0011534-DNA,A10,0,122849_A10_MET_T2D974341,Homo sapiens,F,,30,50,-,,0,,,,-'],
         ['WG0011534-DNA', 'E3', 0, '122849', 'MET_T2D974238', 'Homo sapiens', 'male', 13, 50,
          'WG0011534-DNA,E03,0,122849_E03_MET_T2D974238,Homo sapiens,M,,13,50,-,,0,,,,-'],
         ['WG0017831-DNA', 'F11', 0, '124184', 'WTCCCT480968', 'Homo sapiens', 'male', 30, 50,
          'WG0017831-DNA,F11,0,124184_F11_WTCCCT480968,Homo sapiens,M,,30,50,-,,0,,,,-'],
         ['WG0109327-DNA', 'D6', 0, '141863', 'MIG682626', 'Homo sapiens', 'female', 13, 50,
          'WG0109327-DNA,D06,0,141863_D06_MIG682626,Homo sapiens,F,,13,50,-,,0,,,,-']
          ].each do |plate_label, map_description, control, plate_barcode, sample_name, species, gender, volume, concentration, target_row|
          context "for #{plate_label} #{map_description} #{sample_name}" do
            setup do
              @plate_barcode = plate_barcode
              @plate_label = plate_label

              @sample.control = control
              @sample.sample_metadata.gender = gender.titlecase
              @sample.sample_metadata.sample_common_name = species
              @sample.sanger_sample_id = sample_name
              @sample.save

              @map = Map.find_by(description: map_description)
              @well.aliquots.create!(sample: @sample)
              @well.map = @map
              @well.set_requested_volume(volume)
              @well.set_concentration(concentration)
              @well.save

              @target_row = target_row
              @generated_row = ManifestGenerator.generate_manifest_row(@well, @plate_barcode, @plate_label)
            end
            should 'generate the same row' do
              assert @generated_row.is_a?(Array)
              assert_equal 16, @generated_row.size
              assert_equal @target_row, @generated_row.join(',')
            end
          end
        end
      end
    end

    context 'Single Plate and Single Study' do
      setup do
        @user = create :user

        @sample1 = create(:sample, name: 'Sample1', sanger_sample_id: 'STUDY_1_1', sample_metadata_attributes: { sample_common_name: 'Species 1' })
        @sample2 = create :sample, name: 'Sample2', sanger_sample_id: 'STUDY_1_1'
        @sample3 = create :sample, name: 'Sample3', sanger_sample_id: 'STUDY_1_1'

        @study1 = create :study, user: @user
        @study1.samples << @sample1
        @study1.samples << @sample2

        @study1.study_metadata.study_name_abbreviation = 'STUDY'

        @plate1 = create(:plate, barcode: 11111, size: 96, name: 'Plate 1', plate_metadata_attributes: { infinium_barcode: '12345' })

        @well1 = create(:well).tap { |well| well.aliquots.create!(sample: @sample1) }
        @well2 = create(:well).tap { |well| well.aliquots.create!(sample: @sample2) }
        @well3 = create(:well).tap { |well| well.aliquots.create!(sample: @sample3) }

        [@well1, @well2, @well3].each do |well|
          well.set_requested_volume(15)
          well.set_concentration(50)
          well.save
        end

        @plate1.add_and_save_well(@well1, 0, 0)
        @plate1.add_and_save_well(@well2, 0, 1)
        @plate1.add_and_save_well(@well3, 1, 0)

        @pipeline = create(:pipeline)
        @batch = @pipeline.batches.create!
        @batch.requests = [
          @pipeline.request_types.last.create!(study: @study1, asset: @well),
          @pipeline.request_types.last.create!(study: @study1, asset: @well2),
          @pipeline.request_types.last.create!(study: @study1, asset: @well3)
        ]

        @manifest = ManifestGenerator.generate_manifests(@batch, @study1)
      end

      should 'Create a single manifest file' do
        data =  "1,#{@plate1.infinium_barcode},A01,0,#{@plate1.barcode}_A01_#{@sample1.sanger_sample_id},Species 1,U,,15,50,-,,0,,,,-\n"
        data += "2,#{@plate1.infinium_barcode},A02,0,#{@plate1.barcode}_A02_#{@sample2.sanger_sample_id},Homo sapiens,U,,15,50,-,,0,,,,-\n"
        data += "3,#{@plate1.infinium_barcode},B01,0,#{@plate1.barcode}_B01_#{@sample3.sanger_sample_id},Homo sapiens,U,,15,50,-,,0,,,,-\n"

        template = headers + data

        assert_equal template.split(/\n/), remove_date(@manifest).split(/\n/)
      end

      context 'Several Plates and Single Study' do
        setup do
          @plate2 = create(:plate, barcode: 22222, size: 96, name: 'Plate 2', plate_metadata_attributes: { infinium_barcode: '987654' })

          @sample4 = create :sample, name: 'Sample4', sanger_sample_id: 'STUDY_1_4'
          @study1.samples << @sample4

          @well4 = create(:well).tap { |well| well.aliquots.create!(sample: @sample4) }
          @well5 = create(:well).tap { |well| well.aliquots.create!(sample: @sample4) }
          @well6 = create(:well).tap { |well| well.aliquots.create!(sample: @sample4) }

          [@well4, @well5, @well6].each do |well|
            well.set_requested_volume(15)
            well.set_concentration(50)
            well.save
          end

          @plate2.add_and_save_well(@well4, 0, 0)
          @plate2.add_and_save_well(@well5, 0, 1)
          @plate2.add_and_save_well(@well6, 1, 0)

          @batch.requests.concat([
            @pipeline.request_types.last.create!(study: @study1, asset: @well4),
            @pipeline.request_types.last.create!(study: @study1, asset: @well5),
            @pipeline.request_types.last.create!(study: @study1, asset: @well6)
          ])

          @manifest = ManifestGenerator.generate_manifests(@batch, @study1)
        end

        should 'Create a single manifest file' do
          data =  "1,#{@plate1.infinium_barcode},A01,0,#{@plate1.barcode}_A01_#{@sample1.sanger_sample_id},Species 1,U,,15,50,-,,0,,,,-\n"
          data += "2,#{@plate1.infinium_barcode},A02,0,#{@plate1.barcode}_A02_#{@sample2.sanger_sample_id},Homo sapiens,U,,15,50,-,,0,,,,-\n"
          data += "3,#{@plate1.infinium_barcode},B01,0,#{@plate1.barcode}_B01_#{@sample3.sanger_sample_id},Homo sapiens,U,,15,50,-,,0,,,,-\n"
          data += "4,#{@plate2.infinium_barcode},A01,0,#{@plate2.barcode}_A01_#{@sample4.sanger_sample_id},Homo sapiens,U,,15,50,-,,0,,,,-\n"
          data += "5,#{@plate2.infinium_barcode},A02,0,#{@plate2.barcode}_A02_#{@sample4.sanger_sample_id},Homo sapiens,U,,15,50,-,,0,,,,-\n"
          data += "6,#{@plate2.infinium_barcode},B01,0,#{@plate2.barcode}_B01_#{@sample4.sanger_sample_id},Homo sapiens,U,,15,50,-,,0,,,,-\n"

          template = headers + data
          assert_equal template.split(/\n/), remove_date(@manifest).split(/\n/)
        end
      end
    end
  end
end
