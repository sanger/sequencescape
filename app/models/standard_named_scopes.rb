# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module StandardNamedScopes
  def self.included(base)
    base.instance_eval do
      # Date ordering is better specified as "order_most_recently_created_first" or
      # "order_most_recently_updated_last".  These names seem more readable and understandable.
      [:created, :updated].each do |field|
        { first: 'DESC', last: 'ASC' }.each do |position, order_by|
          scope :"order_most_recently_#{field}_#{position}", -> { order("#{quoted_table_name}.#{field}_at #{order_by}") }
        end
      end
    end
  end
end
