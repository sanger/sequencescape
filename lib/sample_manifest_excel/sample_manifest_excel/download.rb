module SampleManifestExcel
  class Download

    STYLES = {unlock: {locked: false, border: { style: :thin, color: "00" }}, empty_cell: {bg_color: '82CAFA', type: :dxf}, wrap_text: {alignment: {horizontal: :center, vertical: :center, wrap_text: true}, border: { style: :thin, color: "00", edges: [:left, :right, :top, :bottom] }}, borders_only: {border: { style: :thin, color: "00" }}}

    attr_reader :sample_manifest, :worksheet, :columns, :type, :styles, :ranges, :ranges_worksheet

    def initialize(sample_manifest, column_list, range_list)
      @sample_manifest = sample_manifest
      @type = sample_manifest.asset_type
      @styles = create_styles
      @ranges = range_list
      add_worksheet("DNA Collections Form")
      create_validation_ranges_worksheet_and_update_absolute_references_in_ranges
      @columns = column_list.set_formula1(ranges).add_references(first_row, last_row).unlock(styles[:unlock].reference)  
      add_attributes
      create_worksheet
      protect_worksheet
      freeze_panes
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
      @worksheet = workbook.add_worksheet(name: name)
    end

    def add_validation_ranges_worksheet(name)
      @validation_ranges_worksheet = workbook.add_worksheet(name: name)
    end

    def add_row(values = [], style = nil, types = nil)
      worksheet.add_row values, types: types || [:string]*values.length, style: style
    end

    def add_rows(n)
      n.times { |i| add_row }
    end

    def columns
      @columns ||= []
    end

    def first_row
      10
    end

    def last_row
      @last_row ||= sample_manifest.samples.count + first_row - 1
    end

    def protect_worksheet
      worksheet.sheet_protection.format_columns = false
      worksheet.sheet_protection.format_rows = false
      worksheet.sheet_protection.password = password
    end

    def freeze_panes(name = :sanger_sample_id)
      worksheet.sheet_view.pane do |pane|
        pane.state = :frozen
        pane.y_split = first_row-1
        pane.x_split = freeze_after_column(name).number
        pane.active_pane = :bottom_right
      end
    end

    def freeze_after_column(name)
      columns.find_by(name)
    end

    def conditional_formatting_rules
      @conditional_formatting_rules ||= {dxfId: styles[:empty_cell].reference, priority: 1, operator: :equal, formula: 'FALSE', type: :cellIs}
    end

  private

    def create_worksheet
      add_row ["DNA Collections Form"]
      add_rows(3)
      add_row ["Study:", sample_manifest.study.abbreviation]
      add_row ["Supplier:", sample_manifest.supplier.name]
      add_row ["No. Plates Sent:", sample_manifest.count]
      add_rows(1)
      add_row columns.headings, styles[:wrap_text].reference
      sample_manifest.samples.each do |sample|
        create_row(sample)
      end
      add_validations
      add_condititional_formatting
    end

    def create_validation_ranges_worksheet_and_update_absolute_references_in_ranges
      workbook.add_worksheet(name: "Ranges", state: :hidden) do |sheet|
        @ranges_worksheet = SampleManifestExcel::ValidationRangeWorksheet.new(ranges, sheet)
        sheet.sheet_protection.password = password
        ranges.set_absolute_references(sheet)
      end
    end

    def add_validations
      columns.with_validations.each do |column|
        worksheet.add_data_validation(column.reference, column.validation.options)
      end
    end

    def add_condititional_formatting
      columns.with_unlocked.each do |column|
        worksheet.add_conditional_formatting column.reference, conditional_formatting_rules
      end
    end

    def add_attributes
      columns.find_by(:sanger_plate_id).attribute = {sanger_human_barcode: Proc.new { |sample| sample.wells.first.plate.sanger_human_barcode }}
      columns.find_by(:well).attribute = {well: Proc.new { |sample| sample.wells.first.map.description }}
      columns.find_by(:sanger_sample_id).attribute = {sanger_sample_id: Proc.new { |sample| sample.sanger_sample_id }}
      columns.find_by(:donor_id).attribute = {sanger_sample_id: Proc.new { |sample| sample.sanger_sample_id }}
    end

    def create_row(sample)
      worksheet.add_row do |row|
        columns.each do |k, column|
          row.add_cell column.actual_value(sample), type: column.type, style: column.unlocked
        end
      end
    end

    def create_styles
      {}.tap do |s| 
        STYLES.each do |name, options|
          s[name] = SampleManifestExcel::Style.new workbook, options
        end
      end
    end

  end
end