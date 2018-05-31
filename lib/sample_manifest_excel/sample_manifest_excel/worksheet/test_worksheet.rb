module SampleManifestExcel
  module Worksheet
    ##
    # A test worksheet is necessary for testing uploads.
    class TestWorksheet < Base
      include Helpers::Worksheet

      attr_accessor :data, :no_of_rows, :study, :supplier, :count, :type, :validation_errors, :missing_columns, :manifest_type, :partial

      attr_reader :dynamic_attributes, :tags

      def initialize(attributes = {})
        super
        @validation_errors ||= []
        create_library_type
        create_reference_genome
        create_dynamic_attributes
        create_requests
        create_styles
        add_title_and_description(study, supplier, count)
        add_headers
        add_data
      end

      def last_row
        @last_row ||= first_row + no_of_rows
      end

      # Adds title and description (study abbreviation, supplier name, number of assets sent)
      # to a worksheet.

      def add_title_and_description(study, supplier, count)
        add_row ['DNA Collections Form']
        add_rows(3)
        add_row ['Study:', study]
        add_row ['Supplier:', supplier]
        add_row ["No. #{type} Sent:", count]
        add_rows(1)
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

      def create_samples
        first_to_last.each do |i|
          create_asset do |asset|
            sample = asset.samples.first
            unless validation_errors.include?(:sample_manifest)
              sample.sample_manifest = sample_manifest
              sample.save
            end
            dynamic_attributes[i][:sanger_sample_id] = sample.sanger_sample_id
            dynamic_attributes[i][:sanger_tube_id] = asset.human_barcode
          end
        end
      end

      def assets
        @assets ||= []
      end

      def add_cell_data(column, n, partial)
        if partial && empty_row?(n)
          (data[column.name] || dynamic_attributes[n][column.name]) unless empty_columns.include?(column.name)
        elsif validation_errors.include?(:insert_size_from) && column.name == 'insert_size_from' && n == first_row
          nil
        else
          data[column.name] || dynamic_attributes[n][column.name]
        end
      end

      def first_to_last
        first_row..last_row
      end

      def empty_row?(n)
        (n == last_row) || (n == (last_row - 1))
      end

      def empty_columns
        ['supplier_name', 'tag_oligo', 'tag2_oligo']
      end

      def manifest_type
        @manifest_type ||= '1dtube'
      end

      def sample_manifest
        @sample_manifest ||= FactoryBot.create(:sample_manifest, asset_type: manifest_type, rapid_generation: true)
      end

      def multiplexed_library_tube
        @multiplexed_library_tube ||= FactoryBot.create(:multiplexed_library_tube)
      end

      private

      def create_asset
        asset = if ['multiplexed_library', 'library'].include? manifest_type
                  FactoryBot.create(:library_tube_with_barcode)
                else
                  FactoryBot.create(:sample_tube_with_sanger_sample_id)
                end
        assets << asset
        yield(asset) if block_given?
      end

      def create_requests
        assets.each do |asset|
          FactoryBot.create(:external_multiplexed_library_tube_creation_request, asset: asset, target_asset: multiplexed_library_tube) if manifest_type == 'multiplexed_library'
        end
      end

      def initialize_dynamic_attributes
        {}.tap do |hsh|
          first_to_last.each do |i|
            hsh[i] = {}
          end
        end.with_indifferent_access
      end

      def create_dynamic_attributes
        @dynamic_attributes = initialize_dynamic_attributes
        create_samples
        create_tags
      end

      def create_library_type
        unless validation_errors.include?(:library_type)
          LibraryType.where(name: data[:library_type]).first_or_create
        end
      end

      def create_reference_genome
        unless validation_errors.include?(:reference_genome)
          ReferenceGenome.where(name: data[:reference_genome]).first_or_create
        end
      end

      def create_tags
        oligos = Tags::ExampleData.new.take(first_row, last_row, validation_errors.include?(:tags))
        dynamic_attributes.each do |k, _v|
          dynamic_attributes[k].merge!(oligos[k])
        end
      end
    end
  end
end
