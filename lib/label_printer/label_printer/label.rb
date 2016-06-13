module LabelPrinter
	module Label

		module BasePlateLabel

			def default_label(plate)
				{top_left: "#{date_today}",
					bottom_left: "#{plate.sanger_human_barcode}",
					barcode: "#{plate.ean13_barcode}"}
			end

			def date_today
				Date.today.strftime("%e-%^b-%Y")
			end
		end

	end
end