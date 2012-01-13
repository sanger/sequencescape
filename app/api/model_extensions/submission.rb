module ModelExtensions::Submission
  def self.included(base)
    base.class_eval do
      named_scope :include_orders, :include => { :orders => { :study => :uuid_object, :project => :uuid_object, :assets => :uuid_object } }

      def order
        orders.first
      end
    end
  end
end
