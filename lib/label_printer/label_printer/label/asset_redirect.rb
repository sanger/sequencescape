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
				_assets.each {|asset| add_barcode(asset)}
			end

			def _assets
				if printables.is_a? Asset
					[printables]
				else
					ids = printables.select{|id, check| check == "true"}.keys
					Asset.find(ids)
				end
			end

			def add_barcode(asset)
		    unless asset.barcode.present?
	        asset.barcode = AssetBarcode.new_barcode
	        asset.save!
	      end
      end

		end

	end
end