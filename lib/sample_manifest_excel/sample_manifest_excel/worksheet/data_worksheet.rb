module SampleManifestExcel

	module Worksheet

	  class DataWorksheet < Base

      def create_worksheet
      	insert_axlsx_worksheet("DNA Collections Form")
      	add_title_and_info
      	add_columns
        freeze_panes
      end

    	def add_title_and_info
        add_row ["DNA Collections Form"]
        add_rows(3)
        add_row ["Study:", sample_manifest.study.abbreviation]
        add_row ["Supplier:", sample_manifest.supplier.name]
        add_row ["No. #{type} Sent:", sample_manifest.count]
        add_rows(1)
    	end

      def add_columns
        prepare_columns
        add_columns_headings
        add_data
        columns.add_validation_and_conditional_formatting axlsx_worksheet
      end

      def prepare_columns
        columns.prepare_columns(first_row, last_row, styles, ranges)
      end

    	def add_columns_headings
  			add_row columns.headings, styles[:wrap_text].reference
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