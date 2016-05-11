module SampleManifestExcel

	module Worksheet

	  class DataWorksheet < Base

    	def add_title_and_info
        add_row ["DNA Collections Form"]
        add_rows(3)
        add_row ["Study:", sample_manifest.study.abbreviation]
        add_row ["Supplier:", sample_manifest.supplier.name]
        add_row ["No. #{type} Sent:", sample_manifest.count]
        add_rows(1)
    	end

    	def add_columns_headings
  			add_row columns.headings, styles[:wrap_text].reference
    	end

      def create_worksheet
      	prepare_columns
      	add_title_and_info
      	add_columns_headings
      	add_data
        add_validations
        add_condititional_formatting
        freeze_panes
        self
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
          pane.x_split = freeze_after_column(name)
          pane.active_pane = :bottom_right
        end
      end

      def freeze_after_column(name)
        columns.find_by(name) ? columns.find_by(name).number : 0
      end

      def first_row
        10
      end

      def last_row
        @last_row ||= sample_manifest.samples.count + first_row - 1
      end

	  end

	end

end