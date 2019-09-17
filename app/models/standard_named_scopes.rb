module StandardNamedScopes
  def self.included(base)
    base.instance_eval do
      # Date ordering is better specified as "order_most_recently_created_first" or
      # "order_most_recently_updated_last".  These names seem more readable and understandable.
      %i[created updated].each do |field|
        { first: 'DESC', last: 'ASC' }.each do |position, order_by|
          scope :"order_most_recently_#{field}_#{position}", -> { order("#{quoted_table_name}.#{field}_at #{order_by}") }
        end
      end
    end
  end
end
