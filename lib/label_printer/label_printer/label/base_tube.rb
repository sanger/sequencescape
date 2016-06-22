module LabelPrinter
	module Label

		class BaseTube

			def to_h
				{labels: {body: labels}}
			end

			def labels
				[].tap do |l|
					tubes.each do |tube|
						label = create_label(tube)
						count.times { l.push(label) }
					end
				end
			end

			def count
				1
			end

			def create_label(tube)
				{main_label: label(tube)}
			end

			def label(tube)
				{top_line: top_line,
					middle_line: middle_line(tube),
					bottom_line: bottom_line,
					round_label_top_line: round_label_top_line(tube),
					round_label_bottom_line: round_label_bottom_line(tube),
					barcode: barcode(tube)}
			end

			def bottom_line
				date_today
			end

			def round_label_top_line(tube)
				tube.prefix
			end

			def round_label_bottom_line(tube)
				tube.barcode
			end

			def barcode(tube)
				tube.ean13_barcode
			end

			def date_today
				Date.today.strftime("%e-%^b-%Y")
			end

		end
	end
end