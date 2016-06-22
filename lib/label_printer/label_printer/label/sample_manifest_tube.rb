module LabelPrinter
	module Label

		class SampleManifestTube <BaseTube

			attr_reader :sample_manifest

			def initialize(options)
				@sample_manifest = options[:sample_manifest]
				@only_first_label = options[:only_first_label]
			end

			def top_line
				sample_manifest.study.abbreviation
			end

			def middle_line(tube)
				tube.barcode
			end

			def tubes
				return [sample_manifest.samples.first.assets.first] if @only_first_label
				sample_manifest.samples.map {|sample| sample.assets.first}
			end

		end
	end
end