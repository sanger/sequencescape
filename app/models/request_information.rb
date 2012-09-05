class RequestInformation < ActiveRecord::Base
  belongs_to :request_information_type
  belongs_to :request

  named_scope :information_type, lambda {|*args| {:conditions => { :request_information_type_id => args[0]} } }
end
