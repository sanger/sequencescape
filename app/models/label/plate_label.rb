module Label

	class PlateLabel

		attr_reader :plates, :plate_purpose, :user_login

		def initialize(options)
			@plates = options[:plates]
			@plate_purpose = options[:plate_purpose]
			@user_login = options[:user_login]
		end

		def to_h
			{labels: {body: labels}}
		end

		def labels
			[].tap do |l|
				plates.each do |plate|
					l.push({main_label:
										{top_left: "#{date_today}",
										bottom_left: "#{plate.sanger_human_barcode}",
										top_right: "#{plate_purpose.name.to_s}",
										bottom_right: "#{user_login} #{plate.find_study_abbreviation_from_parent}",
										top_far_right: "#{plate.parent.try(:barcode)}",
										barcode: "#{plate.ean13_barcode}"}})
				end
			end
		end

		def date_today
			Date.today.strftime("%e-%^b-%Y")
		end

	end

end
