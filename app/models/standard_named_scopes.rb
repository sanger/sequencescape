module StandardNamedScopes
  def self.included(base)
    base.instance_eval do
      named_scope :readonly, { :readonly => true }

      # Date ordering is better specified as "order_most_recently_created_first" or
      # "order_most_recently_updated_last".  These names seem more readable and understandable.
      [ :created, :updated ].each do |field|
        { :first => 'DESC', :last => 'ASC' }.each do |position, order_by|
          named_scope :"order_most_recently_#{field}_#{position}", :order => "#{self.quoted_table_name}.#{field}_at #{order_by}"
        end
      end
    end
  end
end
