# frozen_string_literal: true
module StandardNamedScopes
  SORT_FIELDS = %i[created updated].freeze
  SORT_ORDERS = { first: 'DESC', last: 'ASC' }.freeze

  def self.included(base)
    base.instance_eval do
      # Date ordering is better specified as "order_most_recently_created_first" or
      # "order_most_recently_updated_last".  These names seem more readable and understandable.
      SORT_FIELDS.each do |field|
        SORT_ORDERS.each do |position, order_by|
          scope :"order_most_recently_#{field}_#{position}",
                lambda { order("#{quoted_table_name}.#{field}_at #{order_by}") }
        end
      end
    end
  end
end
