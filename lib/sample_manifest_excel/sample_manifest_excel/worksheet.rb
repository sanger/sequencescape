module SampleManifestExcel

  class Worksheet

  	attr_accessor :axlsx_worksheet, :columns, :ranges, :sample_manifest, :styles, :name

  	def initialize(attributes = {})
  	  attributes.each do |name, value|
        send("#{name}=", value)
      end
  	  @name = axlsx_worksheet.name
  	end

  	def add_row(values = [], style = nil, types = nil)
			axlsx_worksheet.add_row values, types: types || [:string]*values.length, style: style
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

  	def add_title_and_info
      add_row ["DNA Collections Form"]
      add_rows(3)
      add_row ["Study:", sample_manifest.study.abbreviation]
      add_row ["Supplier:", sample_manifest.supplier.name]
      add_row ["No. #{sample_manifest.asset_type.pluralize.capitalize} Sent:", sample_manifest.count]
      add_rows(1)
  	end

  	def add_columns_headings
			add_row columns.headings, styles[:wrap_text].reference
  	end

  	def add_ranges
  	  ranges.each do |k, range|
  	    add_row range.options
  	  end
  	  self
  	end

    def create_data_worksheet
    	prepare_columns
    	add_attributes
    	add_title_and_info
    	add_columns_headings
    	add_data
      add_validations
      add_condititional_formatting
      freeze_panes
      self
    end

  	def add_attributes
      columns.find_by(:sanger_plate_id).attribute = {sanger_human_barcode: Proc.new { |sample| sample.wells.first.plate.sanger_human_barcode }}
      columns.find_by(:well).attribute = {well: Proc.new { |sample| sample.wells.first.map.description }}
      columns.find_by(:sanger_sample_id).attribute = {sanger_sample_id: Proc.new { |sample| sample.sanger_sample_id }}
      columns.find_by(:donor_id).attribute = {sanger_sample_id: Proc.new { |sample| sample.sanger_sample_id }}
    end

    def prepare_columns
    	columns.prepare_validations(ranges).add_references(first_row, last_row).unlock(styles[:unlock].reference).prepare_conditional_formatting_rules(styles, ranges)
    end

    def add_data
			sample_manifest.samples.each { |sample| create_row(sample) }
    end

    def create_row(sample)
      axlsx_worksheet.add_row do |row|
        columns.each do |k, column|
          row.add_cell column.actual_value(sample), type: column.type, style: column.unlocked
        end
      end
    end

    def add_validations
      columns.with_validations.each do |column|
        axlsx_worksheet.add_data_validation(column.reference, column.validation.options)
      end
    end

    def add_condititional_formatting
      columns.with_cf_rules.each do |column|
        axlsx_worksheet.add_conditional_formatting column.reference, column.cf_options
      end
    end

    def freeze_panes(name = :sanger_sample_id)
      axlsx_worksheet.sheet_view.pane do |pane|
        pane.state = :frozen
        pane.y_split = first_row-1
        pane.x_split = freeze_after_column(name).number
        pane.active_pane = :bottom_right
      end
    end

    def freeze_after_column(name)
      columns.find_by(name)
    end

    def protect(password)
    	axlsx_worksheet.sheet_protection.format_columns = false
      axlsx_worksheet.sheet_protection.format_rows = false
    	axlsx_worksheet.sheet_protection.password = password
    end

  end

end