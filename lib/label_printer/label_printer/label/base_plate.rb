module LabelPrinter
	module Label

		class BasePlate

			include Label::MultipleLabels

			attr_reader :label_template_id
			attr_accessor :plates, :count

			alias_method :assets, :plates

			def initialize(options={})
				@label_template_id = 15
				@plates = []
				@count = 1
			end

			def create_label(plate)
				{top_left: top_left,
					bottom_left: bottom_left(plate),
					top_right: top_right(plate),
					bottom_right: bottom_right(plate),
					top_far_right: top_far_right(plate),
					barcode: barcode(plate)}
			end

			def top_left
				date_today
			end

			def bottom_left(plate)
				plate.sanger_human_barcode
			end

			def top_right(plate)
			end

			def bottom_right(plate)
			end

			def top_far_right(plate)
			end

			def barcode(plate)
				plate.ean13_barcode
			end

			def date_today
				Date.today.strftime("%e-%^b-%Y")
			end

		end

	end
end