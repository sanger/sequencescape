module LabelPrinter
	module Label

		class BasePlate

			def to_h
				{labels: {body: labels}}
			end

			def labels
				[].tap do |l|
					plates.each do |plate|
						label = create_label(plate)
						count.times { l.push(label) }
					end
				end
			end

			def count
				1
			end

			def create_label(plate)
				{main_label: label(plate)}
			end

			def label(plate)
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

			def top_right(plate=nil)
			end

			def bottom_right(plate)
			end

			def top_far_right(plate)
			end

			def barcode(plate)
				plate.ean13_barcode
			end

			def plates
			end

			def date_today
				Date.today.strftime("%e-%^b-%Y")
			end

		end

	end
end