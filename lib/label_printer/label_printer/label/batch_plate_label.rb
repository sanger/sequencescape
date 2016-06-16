
module LabelPrinter
	module Label

		class BatchPlateLabel

			include BasePlateLabel

			attr_reader :count, :printable, :batch

			def initialize(options)
				@count = options[:count]
				@printable = options[:printable]
				@batch = options[:batch]
			end

			def top_right
				batch.study.abbreviation
			end

			def bottom_right(plate)
				"#{batch.output_plate_role} #{batch.output_plate_purpose.name} #{plate.barcode}"
			end

			def plates
				barcodes = printable.select{|barcode, tick| tick == 'on'}.keys
				batch.output_plates.select {|plate| barcodes.include?(plate.barcode)}
			end

		end
	end
end