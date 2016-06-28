module LabelPrinter
	module Label

		class SampleManifestPlate< BasePlate

			attr_reader :sample_manifest, :only_first_label

			def initialize(options)
				super
				@sample_manifest = options[:sample_manifest]
				@only_first_label = options[:only_first_label]
			end

			def top_right(plate)
				PlatePurpose.stock_plate_purpose.name.to_s
			end

			def bottom_right(plate)
				"#{sample_manifest.study.abbreviation} #{plate.barcode}"
			end

			def plates
				return [_plates.first] if only_first_label
				_plates
			end

			private

			def _plates
				if sample_manifest.rapid_generation?
					sample_manifest.core_behaviour.plates
				else
					sample_manifest.core_behaviour.samples.map { |s| s.primary_receptacle.plate }.uniq
				end
			end

		end
	end
end