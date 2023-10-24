# frozen_string_literal: true
module LabelPrinter
  module Label
    module MultipleLabels
      attr_accessor :count

      def labels
        return [] unless assets

        create_labels
      end

      def create_labels
        [].tap do |l|
          assets.each do |asset|
            label = build_label(asset)
            count.times { l.push(label) }
          end
        end
      end

      def count
        (@count || 1).to_i
      end
    end
  end
end
