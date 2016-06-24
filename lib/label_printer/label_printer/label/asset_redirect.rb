module LabelPrinter
	module Label

		class AssetRedirect

			attr_reader :printables

			def initialize(options)
				@printables = options[:printables]
			end

			def to_h
				if assets.first.is_a? Plate
					return AssetPlate.new(assets).to_h
				elsif assets.first.is_a? Tube
					return AssetTube.new(assets).to_h
				end
			end

			def assets
				if printables.is_a? Asset
					[printables]
				else
					ids = printables.select{|id, tick| tick == "true"}.keys
					Asset.find(ids)
				end
			end

		end

	end
end