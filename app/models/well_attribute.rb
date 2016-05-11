#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

require 'aasm'

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

  def measured_volume=(volume)
    self.initial_volume = volume
    self.current_volume = volume
    super
  end

  def initial_volume=(volume)
    super if initial_volume.nil?
  end

  def quantity_in_nano_grams
    return nil if current_volume.nil? || concentration.nil?
    return nil if current_volume < 0 || concentration < 0

    (current_volume * concentration).to_i
  end

  def quantity_in_micro_grams
    return nil if current_volume.nil? || concentration.nil?
    return nil if current_volume < 0 || concentration < 0
    (current_volume * concentration)/1000
  end

  aasm_event :pass_pico_test do
    transitions :to => :Pass, :from => [:ungraded, :Repeat, :Fail, :Pass]
  end

  aasm_event :fail_pico_test do
    transitions :to => :Fail, :from => [:Repeat, :Fail, :Pass]
    transitions :to => :Repeat, :from => [:ungraded]
  end

end
