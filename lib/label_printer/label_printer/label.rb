# frozen_string_literal: true
module LabelPrinter
  module Label
    module MultipleLabels # rubocop:todo Style/Documentation
      attr_accessor :count

      def to_h
        # { labels: labels }
        { labels: create_labels, label_name: 'main_label' }
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
