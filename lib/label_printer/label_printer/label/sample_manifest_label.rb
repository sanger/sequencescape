module LabelPrinter
	module Label

		class SampleManifestLabel

			include BasePlateLabel

			attr_reader :sample_manifest

			def initialize(options)
				@sample_manifest = options[:sample_manifest]
				@only_first_label = options[:only_first_label]
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

			def top_right
				PlatePurpose.stock_plate_purpose.name.to_s
			end

			def bottom_right(plate)
				"#{sample_manifest.study.abbreviation} #{plate.barcode}"
			end

			def plates
				return [sample_manifest.core_behaviour.plates.first] if @only_first_label
				sample_manifest.core_behaviour.plates
			end

		end
	end
end