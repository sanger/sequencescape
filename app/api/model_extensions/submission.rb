#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
module ModelExtensions::Submission
  def self.included(base)
    base.class_eval do
      scope :include_orders, -> { includes( :orders => { :study => :uuid_object, :project => :uuid_object, :assets => :uuid_object } ) }

      def order
        orders.first
      end
    end
  end
end
