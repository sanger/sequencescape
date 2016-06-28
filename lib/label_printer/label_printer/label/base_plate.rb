module LabelPrinter
	module Label

		class BasePlate

			attr_reader :label_template_id
			attr_accessor :plates, :count

			def initialize(options={})
				@label_template_id = 14
				@count = 1
				@plates = []
			end

			def to_h
				labels.merge(label_template)
			end

			def labels
				{labels: {body: create_labels}}
			end

			def create_labels
				[].tap do |l|
					plates.each do |plate|
						label = label(plate)
						count.times { l.push(label) }
					end
				end
			end

			def label(plate)
				{main_label: create_label(plate)}
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

			def label_template
				{label_template_id: label_template_id}
			end

			def date_today
				Date.today.strftime("%e-%^b-%Y")
			end

		end

	end
end