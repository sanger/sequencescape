module Heron
  module Factories
    class TubeRack
      include ActiveModel::Model

      attr_accessor :barcode

      validates_presence_of :barcode, :tubes

      validate :check_tubes

      def tubes=(attributes)
        attributes.each do |tube|
          tubes << Heron::Factories::Tube.new(tube.except(:location))
        end
      end

      def tubes
        @tubes ||= []
      end

      private

      def check_tubes
        tubes.each do |tube|
          next if tube.valid?

          tube.errors.each do |k, v|
            errors.add(k, v)
          end
        end
      end

    end
  end
end
