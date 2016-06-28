
module LabelPrinter
	module Label

		class BatchTube < BaseTube

			attr_reader :count, :printable, :batch, :stock

			def initialize(options)
				@count = options[:count].to_i
				@printable = options[:printable]
				@batch = options[:batch]
				@stock =options[:stock]
			end

			def top_line(tube)
				if stock
					tube.name
				else
					if batch.multiplexed?
						tube.tag.nil? ? tube.name : "(#{tube.tag}) #{tube.id}"
					else
						tube.tube_name
					end
				end
			end

			def tubes
				if stock
					if batch.multiplexed?
						#all info on a label including barcode is about target_asset first child
						tubes = requests.map {|request| request.target_asset.children.first}
					else
						#all info on a label including barcode is about target_asset stock asset
						tubes = requests.map {|request| request.target_asset.stock_asset}
					end
				else
					#all info on a label including barcode is about target_asset
					tubes = requests.map {|request| request.target_asset}
				end
			end

			private

			def requests
				request_ids = printable.select{|barcode, tick| tick == 'on'}.keys
				requests = Request.find request_ids
			end

		end
	end
end