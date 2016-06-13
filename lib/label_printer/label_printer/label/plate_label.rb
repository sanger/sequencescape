module LabelPrinter
	module Label

		class PlateLabel

			include BasePlateLabel

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
						l.push({main_label: create_label(plate)})
					end
				end
			end

			def create_label(plate)
				default_label(plate).merge(label(plate))
			end

			def label(plate)
				{top_right: "#{plate_purpose.name.to_s}",
					bottom_right: "#{user_login} #{plate.find_study_abbreviation_from_parent}",
					top_far_right: "#{plate.parent.try(:barcode)}"}
			end

		end
	end
end
