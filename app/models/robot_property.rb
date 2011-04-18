class RobotProperty < ActiveRecord::Base
  belongs_to :robot
  
  acts_as_audited :on => [:destroy, :update]
end
