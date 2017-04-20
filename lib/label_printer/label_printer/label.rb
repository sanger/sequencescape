module LabelPrinter
  module Label
    module MultipleLabels
      attr_accessor :count

      def to_h
        { labels: labels }
      end

      def labels
        return [] unless assets
        { body: create_labels }
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
        { main_label: create_label(asset) }
      end

      def count
        (@count || 1).to_i
      end
    end
  end
end
