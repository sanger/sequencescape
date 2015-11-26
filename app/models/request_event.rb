#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class RequestEvent < ActiveRecord::Base

  belongs_to :request

  validates :request, :to_state, :current_from, :event_name, :presence => true

  validates_inclusion_of :event_name, :in => ['created','state_changed','destroyed']

 scope :current, -> { where( :current_to => nil ) }

  def expire!(date_time)
    raise StandardError, 'This event has already expired!' unless current_to.nil?
    self.update_attributes!(:current_to=>date_time)
  end

end
