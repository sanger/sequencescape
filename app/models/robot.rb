class Robot < ActiveRecord::Base
   validates_presence_of :name,:location
   has_many :robot_properties
   
   acts_as_audited :on => [:destroy, :update]

   def max_beds
     return 0 if self.robot_properties.nil?
     max_plates = self.robot_properties.find_by_key('max_plates')
     if !(max_plates.nil? || max_plates.value.nil?)
       return max_plates.value.to_i
     end

     0
   end

   def self.prefix
     "RB"
   end

   def self.find_from_barcode(code)
    human_robot_barcode = Barcode.number_to_human(code)
    robot = Robot.find_by_barcode(human_robot_barcode)
    robot ||= Robot.find_by_id(human_robot_barcode)
   end

   def self.valid_barcode?(code)
     begin
     Barcode.barcode_to_human!(code, self.prefix)
     self.find_from_barcode(code) # an exception is raise if not found
    rescue
      return false
    end

    true
   end

end
