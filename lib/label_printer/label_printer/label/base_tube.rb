module LabelPrinter
	module Label

		class BaseTube

			include Label::MultipleLabels

			attr_reader :label_template_id
			attr_accessor :tubes, :count

			alias_method :assets, :tubes

			def initialize(options={})
				@label_template_id = 16
				@count = 1
				@tubes = []
			end

			def create_label(tube)
				{top_line: top_line(tube),
					middle_line: middle_line(tube),
					bottom_line: bottom_line,
					round_label_top_line: round_label_top_line(tube),
					round_label_bottom_line: round_label_bottom_line(tube),
					barcode: barcode(tube)}
			end

			def top_line(tube)
			end

			def middle_line(tube)
				tube.barcode
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