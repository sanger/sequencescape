# frozen_string_literal: true

require_dependency 'sample_manifest_excel/tags'

module SampleManifestExcel
  module Worksheet
    ##
    # A test worksheet is necessary for testing uploads.
    class TestWorksheet < SequencescapeExcel::Worksheet::Base
      include SequencescapeExcel::Helpers::Worksheet

      self.worksheet_name = 'DNA Collections Form'

      attr_accessor :data, :no_of_rows, :study, :supplier, :count, :type, :validation_errors, :missing_columns, :partial, :cgap, :num_plates, :num_samples_per_plate
      attr_reader :dynamic_attributes, :tags
      attr_writer :manifest_type

      def initialize(attributes = {})
        super
        @validation_errors ||= []
        if type == 'Plates'
          # create a worksheet for Plates
          create_plate_dynamic_attributes
        else
          # by default create a worksheet for Tubes
          create_library_type
          create_reference_genome
          create_tube_dynamic_attributes
          create_tube_requests
        end
        create_styles
        add_title_and_description(study, supplier, count)
        add_headers
        add_data
      end

      def last_row
        @last_row ||= compute_last_row
      end

      def compute_last_row
        if %w[plate_default plate_full plate_rnachip].include? manifest_type
          computed_first_row + (num_plates * num_samples_per_plate) - 1
        else
          computed_first_row + no_of_rows
        end
      end

      def assets
        @assets ||= []
      end

      def empty_columns
        %w[supplier_name i7 i5]
      end

      def manifest_type
        @manifest_type ||= 'tube_default'
      end

      def sample_manifest
        @sample_manifest ||= create_sample_manifest
      end

      def create_sample_manifest
        if %w[plate_default plate_full plate_rnachip].include? manifest_type
          FactoryBot.create(:pending_plate_sample_manifest, num_plates: num_plates, num_samples_per_plate: num_samples_per_plate)
        elsif %w[tube_library_with_tag_sequences].include? manifest_type
          FactoryBot.create(:sample_manifest, asset_type: 'library')
        elsif %w[tube_multiplexed_library tube_multiplexed_library_with_tag_sequences].include? manifest_type
          FactoryBot.create(:sample_manifest, asset_type: 'multiplexed_library')
        elsif %w[tube_rack_default].include? manifest_type
          FactoryBot.create(:tube_rack_manifest, asset_type: 'tube_rack')
        else
          FactoryBot.create(:sample_manifest, asset_type: '1dtube')
        end
      end

      def multiplexed_library_tube
        @multiplexed_library_tube ||= FactoryBot.create(:multiplexed_library_tube)
      end

      private

      def initialize_dynamic_attributes
        {}.tap do |hsh|
          first_to_last.each do |i|
            hsh[i] = {}
          end
        end.with_indifferent_access
      end

      def create_plate_dynamic_attributes
        @dynamic_attributes = initialize_dynamic_attributes
        record_plate_samples
      end

      def record_plate_samples
        sm_sample_assets = sample_manifest.sample_manifest_assets.to_a

        first_to_last.each_with_index do |sheet_row, sample_index|
          cur_sm_sample_asset = sm_sample_assets.fetch(sample_index)

          # Validation errors here indicates problems we WANT not problems we HAVE
          cur_sm_sample_asset.destroy! if validation_errors.include?(:sample_manifest)

          # set the sample id
          dynamic_attributes[sheet_row][:sanger_sample_id] = cur_sm_sample_asset.sanger_sample_id

          # set the plate barcode
          plate_id = cur_sm_sample_asset.asset.plate.id
          # Validation errors here indicates problems we WANT not problems we HAVE
          dynamic_attributes[sheet_row][:sanger_plate_id] = if cgap
                                                              if validation_errors.include?(:sample_plate_id_duplicates)
                                                                'CGAP-99999'
                                                              elsif validation_errors.include?(:sample_plate_id_unrecognised_foreign)
                                                                "INVALID-#{plate_id.to_s.upcase}#{(plate_id % 10).to_s.upcase}"
                                                              else
                                                                "CGAP-#{plate_id.to_s(16).upcase}#{(plate_id % 16).to_s(16).upcase}"
                                                              end
                                                            else
                                                              cur_sm_sample_asset.asset.plate.human_barcode
                                                            end
          # set the well position
          dynamic_attributes[sheet_row][:well] = cur_sm_sample_asset.asset.map_description
        end
      end

      def create_tube_dynamic_attributes
        @dynamic_attributes = initialize_dynamic_attributes
        record_tube_samples
        create_tags
      end

      def record_tube_samples
        tube_counter = 0
        first_to_last.each do |sheet_row|
          build_tube_sample_manifest_asset do |sample_manifest_asset|
            asset = sample_manifest_asset.asset

            # Validation errors here indicates problems we WANT not problems we HAVE
            unless validation_errors.include?(:sample_manifest)
              sample_manifest_asset.sample_manifest = sample_manifest
              sample_manifest_asset.save
            end
            dynamic_attributes[sheet_row][:sanger_sample_id] = sample_manifest_asset.sanger_sample_id
            dynamic_attributes[sheet_row][:sanger_tube_id] = if cgap
                                                               tube_row_num = (sheet_row - computed_first_row) + 1
                                                               if validation_errors.include?(:sample_tube_id_duplicates) && tube_row_num < 3
                                                                 'CGAP-99999'
                                                               else
                                                                 "CGAP-#{tube_row_num.to_s(16).upcase}#{(tube_row_num % 16).to_s(16).upcase}"
                                                               end
                                                             else
                                                               asset.human_barcode
                                                             end
          end
          dynamic_attributes[sheet_row][:tube_barcode] = 'TB1111111' + tube_counter.to_s
          tube_counter += 1
        end
      end

      # Adds title and description (study abbreviation, supplier name, number of assets sent)
      # to a worksheet.
      def add_title_and_description(study, supplier, count)
        add_row ['DNA Collections Form']
        add_rows(3)
        add_row ['Study:', study]
        add_row ['Supplier:', supplier]
        add_row ["No. #{type} Sent:", count]
        add_extra_cells_for_tube_rack(count) if type == 'Tube Racks'
        add_rows(1)
      end

      def add_extra_cells_for_tube_rack(count)
        rack_size = sample_manifest.tube_rack_purpose.size
        add_row ['Rack size:', rack_size]
        count.times do |num|
          axlsx_worksheet.add_row do |row|
            row.add_cell "Rack barcode (#{num + 1}):", type: :string
            row.add_cell "RK1111111#{num}", type: :string, style: styles[:unlocked_no_border].reference
          end
        end
      end

      def first_to_last
        computed_first_row..last_row
      end

      def empty_row?(row_num)
        (row_num == last_row) || (row_num == (last_row - 1))
      end

      def add_data
        first_to_last.each do |n|
          axlsx_worksheet.add_row do |row|
            columns.each do |column|
              row.add_cell add_cell_data(column, n, partial), type: column.type, style: styles[:unlocked].reference
            end
          end
        end
      end

      def add_cell_data(column, row_num, partial)
        if partial && empty_row?(row_num)
          (data[column.name] || dynamic_attributes[row_num][column.name]) unless empty_columns.include?(column.name)
        elsif validation_errors.include?(:insert_size_from) && column.name == 'insert_size_from' && row_num == computed_first_row
          nil
        elsif validation_errors.include?(:sanger_sample_id_invalid) && column.name == 'sanger_sample_id' && row_num == computed_first_row
          'ABC'
        else
          data[column.name] || dynamic_attributes[row_num][column.name]
        end
      end

      def build_tube_sample_manifest_asset
        asset = if %w[tube_multiplexed_library tube_library_with_tag_sequences tube_multiplexed_library_with_tag_sequences].include? manifest_type
                  FactoryBot.create(:empty_library_tube)
                else
                  FactoryBot.create(:empty_sample_tube)
                end
        sma = FactoryBot.build(:sample_manifest_asset, asset: asset.receptacle, sample_manifest: nil)
        assets << asset
        yield(sma) if block_given?
      end

      def create_tube_requests
        assets.each do |asset|
          FactoryBot.create(:external_multiplexed_library_tube_creation_request, asset: asset, target_asset: multiplexed_library_tube) if %w[tube_multiplexed_library tube_multiplexed_library_with_tag_sequences].include? manifest_type
        end
      end

      def create_library_type
        return if validation_errors.include?(:library_type)

        LibraryType.where(name: data[:library_type]).first_or_create
      end

      def create_reference_genome
        return if validation_errors.include?(:reference_genome)

        ReferenceGenome.where(name: data[:reference_genome]).first_or_create
      end

      def create_tags
        if %w[tube_multiplexed_library_with_tag_sequences tube_library_with_tag_sequences].include? manifest_type
          oligos = Tags::ExampleData.new.take(computed_first_row, last_row, validation_errors.include?(:tags))
          dynamic_attributes.each do |k, _v|
            dynamic_attributes[k].merge!(oligos[k])
          end
        elsif %w[tube_multiplexed_library].include? manifest_type
          groups_and_indexes = Tags::ExampleData.new.take_as_groups_and_indexes(computed_first_row, last_row, validation_errors.include?(:tags))
          dynamic_attributes.each do |k, _v|
            dynamic_attributes[k].merge!(groups_and_indexes[k])
          end
        end
      end

      def computed_first_row
        if type == 'Tube Racks'
          first_row + count + 1
        else
          first_row
        end
      end
    end
  end
end
