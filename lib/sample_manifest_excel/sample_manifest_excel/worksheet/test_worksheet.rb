module SampleManifestExcel
  module Worksheet
    class TestWorksheet < Base

      include Helpers

      attr_accessor :data, :no_of_rows, :study, :supplier, :count, :type, :validation_errors, :missing_columns, :manifest_type

      attr_reader :dynamic_attributes, :tags

      def initialize(attributes = {})
        super
        @validation_errors ||= []
        create_library_type
        create_dynamic_attributes
        create_styles
        add_title_and_description(study, supplier, count)
        add_headers
        add_data
      end

      def last_row
        @last_row ||= first_row + no_of_rows
      end

      def add_data
        first_to_last.each do |n|
          axlsx_worksheet.add_row do |row|
            columns.each do |column|
              row.add_cell add_cell_data(column, n), type: column.type, style: styles[:unlocked].reference
            end
          end
        end
      end

      def create_samples
        first_to_last.each do |i|
          sample_tube = FactoryGirl.create(:sample_tube)
          unless validation_errors.include?(:sample_manifest)
            sample_tube.sample.sample_manifest = sample_manifest
            sample_tube.sample.save
          end
          dynamic_attributes[i][:sanger_sample_id] = sample_tube.sample.id
          dynamic_attributes[i][:sanger_tube_id] = sample_tube.sample.assets.first.sanger_human_barcode
        end
      end

      def add_cell_data(column, n)
        unless validation_errors.include?(:insert_size_from) && column.name == "insert_size_from" && n == first_row
          data[column.name] || dynamic_attributes[n][column.name]
        end
      end

      def first_to_last
        first_row..last_row
      end

      def manifest_type
        @manifest_type ||= '1dtube'
      end

      def sample_manifest
        @sample_manifest ||= FactoryGirl.create(:sample_manifest, asset_type: manifest_type, rapid_generation: true)
      end

      class Tags

        BASES = ['A', 'C', 'G', 'T'].freeze

        attr_reader :tag_oligos, :tag2_oligos

        def initialize
          create_products
        end

        def take(first, last, duplicate = false)
          {}.tap do |hsh|
            (first..last).each_with_index do |n, i|
              hsh[n] = { tag_oligo: tag_oligos[i].join, tag2_oligo: tag2_oligos[i].join }
            end
            hsh[last] = hsh[first] if duplicate
          end
        end

      private

        def create_products
          @tag_oligos = BASES.product(BASES)
          @tag2_oligos = tag_oligos.reverse
        end
      end

    private

     

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
        unless(validation_errors.include?(:library_type))
          LibraryType.where(name: data[:library_type]).first_or_create
        end
      end

      def create_tags
        @tags = Tags.new
        oligos = tags.take(first_row, last_row, validation_errors.include?(:tags))
        dynamic_attributes.each do |k, _v|
          dynamic_attributes[k].merge!(oligos[k])
        end
      end

    end
  end
end
