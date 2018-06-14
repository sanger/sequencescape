
module ModelExtensions::Submission
  def self.included(base)
    base.class_eval do
      scope :include_orders, -> { includes(orders: { study: :uuid_object, project: :uuid_object, assets: [:uuid_object, aliquots: Io::Aliquot::PRELOADS] }) }

      def order
        orders.first
      end
    end
  end
end
