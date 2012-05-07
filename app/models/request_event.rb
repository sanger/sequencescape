class RequestEvent < ActiveRecord::Base
  belongs_to :request
  belongs_to :project
  belongs_to :study

  validates_presence_of :request, :to_state, :event_name
end
