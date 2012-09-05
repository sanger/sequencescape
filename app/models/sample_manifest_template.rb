class SampleManifestTemplate < ActiveRecord::Base
  serialize :default_values, Hash
  serialize :cell_map, Hash

  def self.populate()
    transaction do
      base_template = SampleManifestTemplate.create!(
        :name => "default layout",
        :path => "/data/base_manifest.xls",
        :cell_map => {
          :study => [4,1],
          :supplier => [5,1],
          :number_of_plates => [6,1]
        }
      )

      unless RAILS_ENV == "production"
        base2_template = SampleManifestTemplate.create!(
          :name => "test layout",
          :path => "/data/base2_manifest.xls",
          :cell_map => {
            :study => [3,1],
            :supplier => [9,0],
            :number_of_plates => [6,1]
          },
          :default_values => {
            "GENDER" => "Male"
          }
        )
      end
    end
  end

  def read_column_position(manifest, worksheet)
    Hash[worksheet.row(manifest.spreadsheet_header_row).each_with_index.map { |name, index| [name && name.strip.gsub(/\s+/," "), index] }]
  end
  private :read_column_position

  def fill_row_with_default_values(worksheet, current_row, default_values)
    return unless default_values
    default_values.each do |key, value|
      position = @column_position_map[key]
      next unless position
      worksheet[current_row, position] = value
    end
  end
  private :fill_row_with_default_values

  def set_value(worksheet, cell_name, value)
    row_col = cell_map[cell_name]
    return nil unless row_col
    row, col = row_col
    worksheet.row(row)[col] = value
    return value
  end
  private :set_value

  def generate(manifest)
    spreadsheet = Spreadsheet.open(RAILS_ROOT + (self.path || '/data/base_manifest.xls'))
    worksheet   = spreadsheet.worksheets.first

    @column_position_map = read_column_position(manifest, worksheet)
    barcode_position     = @column_position_map['SANGER PLATE ID']
    position_position    = @column_position_map['WELL']
    sample_id_position   = @column_position_map['SANGER SAMPLE ID']

    set_value(worksheet, :study,            manifest.study.abbreviation)
    set_value(worksheet, :supplier,         Supplier.find(manifest.supplier_id).name)
    set_value(worksheet, :number_of_plates, manifest.count)  # NOT 'number_of_plates' BUT number of things!

    current_row = manifest.spreadsheet_offset
    manifest.details do |details|
      worksheet[current_row, barcode_position]   = details[:barcode]
      worksheet[current_row, sample_id_position] = details[:sample_id]
      worksheet[current_row, position_position]  = details[:position] if details.key?(:position)
      fill_row_with_default_values(worksheet, current_row, default_values)

      current_row = current_row + 1
    end

    # Truncate the number of rows in the spreadsheet.  This improves performance dramatically because the
    # number of rows in the original sheet is 9999, which means 20s of unnecessary data processing.  This
    # change causes times to drop to < 1s. An extra offset is required because Excel does things in blocks
    # of 32 rows
    worksheet.dimensions[1] = current_row + 64
    Tempfile.open(File.basename(spreadsheet.io.path)) do |tempfile|
      spreadsheet.write(tempfile.path)  # Write out the spreadsheet
      tempfile.open                     # Reopen the temporary file
      manifest.update_attributes!(:generated => tempfile)
    end
  end

  def create!(attributes = nil, &block)
    attributes ||= {}
    attributes[:asset_type] = self.asset_type if self.asset_type.present?
    SampleManifest.create!(attributes, &block)
  end
end
