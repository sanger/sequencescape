class WellAttribute < ActiveRecord::Base
  belongs_to :assets

  serialize :gender_markers

  state_machine :state, :initial => :ungraded do

    # These states are originally used in SNP
    event :pass_pico_test do
      transition :to => :Pass, :from => [:ungraded, :Repeat, :Fail, :Pass]
    end

    event :fail_pico_test do
      transition :to => :Fail, :from => [:Repeat, :Fail, :Pass]
      transition :to => :Repeat, :from => [:ungraded]
    end
  end


  # TODO Remvoe 'Too Low To Normalise' from the pico_pass column
  # The state of 'Too Low To Normalise' exists in the database (from SNP?)
  # but it doesn't look like AASM can handle spaces in state names.
  # assm_state :'Too Low To Normalise'

  # Since Pass and Fail are used as pico_state values we're forced
  # to use a different transition name.
  def pico_pass
    case self[:pico_pass]
    when 'Too Low To Normalise' then "Fail"
    when nil, '' then 'ungraded'
    else self[:pico_pass]
    end
  end
  
  def quantity_in_nano_grams
    return nil if measured_volume.nil? || concentration.nil?
    return nil if measured_volume < 0 || concentration < 0
    
    (measured_volume * concentration).to_i
  end
  
  
end
