module SampleManifestExcel
  class Download

    attr_reader :sample_manifest, :worksheet, :columns, :type, :last_row

    def initialize(sample_manifest, column_list)
      @sample_manifest = sample_manifest
      @type = sample_manifest.asset_type
      @columns = column_list.add_ranges(first_row, last_row).unlock(unlock)
      add_attributes
      create_worksheet
      protect_worksheet
      freeze_panes
    end

    def save(filename)
      xls.serialize(filename)
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

    def add_row(values = [], types = nil)
      worksheet.add_row values, types: types || [:string]*values.length
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

    def unlock
      @unlock ||= workbook.styles.add_style locked: false
    end

    def protect_worksheet
      worksheet.sheet_protection.password = '1111'
    end

    def freeze_panes
      worksheet.sheet_view.pane do |pane|
        pane.state = :frozen
        pane.y_split = first_row-1
        pane.x_split = freeze_after_column.position
        pane.active_pane = :bottom_right
      end
    end

    def freeze_after_column(name = 'sanger_sample_id')
      columns.find_by(name)
    end

  private

    def create_worksheet
      add_worksheet("DNA Collections Form")
      add_row ["DNA Collections Form"]
      add_rows(3)
      add_row ["Study:", sample_manifest.study.abbreviation]
      add_row ["Supplier:", sample_manifest.supplier.name]
      add_rows(2)
      add_row columns.headings
      sample_manifest.samples.each do |sample|
        create_row(sample)
      end
      add_validations
    end

    def add_validations
      columns.with_validations.each do |column|
        worksheet.add_data_validation(column.range, column.validation)
      end
    end

    def add_attributes
      columns.find_by("sanger_plate_id").attribute = {sanger_human_barcode: Proc.new { |sample| sample.wells.first.plate.sanger_human_barcode }}
      columns.find_by("well").attribute = {well: Proc.new { |sample| sample.wells.first.map.description }}
      columns.find_by("sanger_sample_id").attribute = {sanger_sample_id: Proc.new { |sample| sample.sanger_sample_id }}
      columns.find_by("donor_id").attribute = {sanger_sample_id: Proc.new { |sample| sample.sanger_sample_id }}
    end

    def create_row(sample)
      worksheet.add_row do |row|
        columns.each do |k, column|
          row.add_cell column.actual_value(sample), type: column.type, style: column.unlock_num
        end
      end
    end

  end
end