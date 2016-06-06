module Label

	class PlateLabel

		attr_reader :plates, :plate_purpose, :user_login

		def initialize(options)
			@plates = options[:plates]
			@plate_purpose = options[:plate_purpose]
			@user_login = options[:user_login]
		end

		def to_h
			{labels: labels}
		end

		def labels
			result = []
			plates.each do |plate|
				result.push({main_label:
									{top_left: "#{Date.today}",
									bottom_left: "#{plate.sanger_human_barcode}",
									top_right: "#{plate_purpose.name.to_s}",
									bottom_right: "#{user_login} #{plate.find_study_abbreviation_from_parent}",
									top_far_right: "#{plate.parent.try(:barcode)}",
									barcode: "#{plate.barcode}"}})
			end
			{body: result}
		end

	end

end
