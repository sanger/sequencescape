# frozen_string_literal: true

module LabelPrinter
  module Label
    module MultipleDoubleLabels # rubocop:todo Style/Documentation
      include MultipleLabels

      def create_labels
        [].tap { |l| assets.each { |asset| count.times { l.push(*double_label(asset)) } } }
      end

      def double_label(asset)
        [label(asset), extra_label(asset)]
      end

      # TODO remove
      def extra_label(asset)
        create_extra_label(asset)
      end
    end
  end
end
