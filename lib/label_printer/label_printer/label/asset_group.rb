
module LabelPrinter
	module Label

		class AssetGroup < BasePlate

			attr_reader :printables

			def initialize(options)
				@printables = options[:printables]
			end

			def top_right(plate)
				"#{plate.prefix} #{plate.barcode}"
			end

			def bottom_right(plate)
				"#{plate.name_for_label.to_s} #{plate.barcode}"
			end

			def plates
				ids = printables.select{|id, tick| tick == "true"}.keys
				Asset.find(ids)
			end

		end
	end
end