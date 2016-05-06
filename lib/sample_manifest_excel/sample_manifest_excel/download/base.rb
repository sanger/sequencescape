module SampleManifestExcel
  module Download
    class Base

      STYLES = {unlock: {locked: false, border: { style: :thin, color: "00" }}, empty_cell: {bg_color: '82CAFA', type: :dxf}, wrong_value: {bg_color: "FF0000", type: :dxf}, wrap_text: {alignment: {horizontal: :center, vertical: :center, wrap_text: true}, border: { style: :thin, color: "00", edges: [:left, :right, :top, :bottom] }}, borders_only: {border: { style: :thin, color: "00" }}}

      attr_reader :sample_manifest, :data_worksheet, :type, :styles, :ranges, :ranges_worksheet

      def initialize(sample_manifest, column_list, range_list)
        @sample_manifest = sample_manifest
        @type = sample_manifest.asset_type
        @styles = create_styles
        @ranges = range_list
        data_axlsx_worksheet = add_worksheet("DNA Collections Form")
        ranges_axlsx_worksheet = add_worksheet("Ranges")
        @ranges_worksheet = SampleManifestExcel::Worksheet.new(ranges: ranges, axlsx_worksheet: ranges_axlsx_worksheet, password: password)
        ranges.set_absolute_references(ranges_worksheet)
        @data_worksheet = SampleManifestExcel::Worksheet.new(axlsx_worksheet: data_axlsx_worksheet, columns: column_list, sample_manifest: sample_manifest, styles: styles, ranges: ranges, password: password)
      end

      def save(filename)
        xls.serialize(filename)
      end

      def password
        @password ||= SecureRandom.base64
      end

      def xls
        @xls ||= Axlsx::Package.new
      end

      def workbook
        xls.workbook
      end

      def add_worksheet(name)
        workbook.add_worksheet(name: name)
      end

    private

      def create_styles
        {}.tap do |s|
          STYLES.each do |name, options|
            s[name] = SampleManifestExcel::Style.new workbook, options
          end
        end
      end

    end
  end
end