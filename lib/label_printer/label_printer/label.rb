module LabelPrinter
	module Label

		module MultipleLabels

			attr_accessor :count

			def to_h
				{labels: {body: labels}}
			end

			def labels
				[].tap do |l|
					assets.each do |asset|
						label = label(asset)
						count.times { l.push(label) }
					end
				end
			end

			def label(asset)
				{main_label: create_label(asset)}
			end

			def count
				@count || 1
			end

		end

	end
end