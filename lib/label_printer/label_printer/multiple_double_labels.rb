# frozen_string_literal: true

module LabelPrinter
  module Label
    module MultipleDoubleLabels
      include MultipleLabels

      def create_labels
        [].tap { |l| assets.each { |asset| count.times { l.push(*double_label(asset)) } } }
      end

      def double_label(asset)
        [build_label(asset), build_extra_label(asset)]
      end
    end
  end
end
