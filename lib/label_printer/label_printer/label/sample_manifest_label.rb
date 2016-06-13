module LabelPrinter
	module Label

		class SampleManifestLabel

			include BasePlateLabel

			attr_reader :sample_manifest

			def initialize(options)
				@sample_manifest = options[:sample_manifest]
				@only_first_label = options[:only_first_label]
			end

			def to_h
				{labels: {body: labels}}
			end

			def labels
				case sample_manifest.asset_type
				when '1dtube'
					return tube_labels
	  		when 'plate'
	  			return plate_labels
	  		when 'multiplexed_library'
	  			return multiplexed_labels
	    	end
			end

			def plate_labels
				[].tap do |l|
					sample_manifest.core_behaviour.plates.each do |plate|
						l.push({main_label:
											{top_left: "#{date_today}",
											bottom_left: "#{plate.sanger_human_barcode}",
											top_right: "#{PlatePurpose.stock_plate_purpose.name.to_s}",
											bottom_right: "#{sample_manifest.study.abbreviation} #{plate.barcode}",
											barcode: "#{plate.ean13_barcode}"}})
					end
				end
			end

		end
	end
end