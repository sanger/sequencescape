
module LabelPrinter
	module Label

		class AssetPlate < BasePlate

			attr_reader :plates

			def initialize(options)
				@plates = [options[:asset]]
			end

			def top_right(plate)
				"#{plate.prefix} #{plate.barcode}"
			end

			def bottom_right(plate)
				"#{plate.name_for_label.to_s} #{plate.barcode}"
			end

		end
	end
end