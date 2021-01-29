# frozen_string_literal: true

module LabelPrinter
  module Label
    module MultipleDoubleLabels # rubocop:todo Style/Documentation
      include MultipleLabels

      def create_labels
        [].tap do |l|
          assets.each do |asset|
            count.times { l.push(*double_label(asset)) }
          end
        end
      end

      def double_label(asset)
        [label(asset), extra_label(asset)]
      end

      def extra_label(asset)
        { extra_label: create_extra_label(asset) }
      end
    end
  end
end
