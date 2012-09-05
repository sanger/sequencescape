class WellAttribute < ActiveRecord::Base
  include AASM

  belongs_to :well, :inverse_of => :well_attribute

  serialize :gender_markers
  def gender_markers_string
    gender_markers.try(:to_s)
  end

  aasm_column :pico_pass

  aasm_initial_state :ungraded

  aasm_state :ungraded
  # These states are originally used in SNP
  aasm_state :Pass
  aasm_state :Repeat
  aasm_state :Fail

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

  aasm_event :pass_pico_test do
    transitions :to => :Pass, :from => [:ungraded, :Repeat, :Fail, :Pass]
  end

  aasm_event :fail_pico_test do
    transitions :to => :Fail, :from => [:Repeat, :Fail, :Pass]
    transitions :to => :Repeat, :from => [:ungraded]
  end

end
