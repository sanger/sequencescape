module LabelPrinter
	module Label

		module MultipleLabels

			def to_h
				labels.merge(label_template)
			end

			def labels
				{labels: {body: create_labels}}
			end

			def create_labels
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

			def label_template
				{label_template_id: label_template_id}
			end

		end

	end
end