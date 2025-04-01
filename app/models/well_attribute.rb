# frozen_string_literal: true
require 'aasm'

# Contains qc information regarding a well, in addition to volume information to
# assist with Cherrypicking
# @note Try and use {QcResult} for any future readings, it will automatically
#       update this table for you.
class WellAttribute < ApplicationRecord
  include AASM

  belongs_to :well, inverse_of: :well_attribute, touch: true

  after_update :broadcast_warehouse_message

  serialize :gender_markers, coder: YAML
  def gender_markers_string
    gender_markers.try(:to_s)
  end

  aasm column: :pico_pass, whiny_persistence: true do
    state :ungraded, initial: true

    # These states are originally used in SNP
    state :Pass
    state :Repeat
    state :Fail
  end

  # TODO: Remvoe 'Too Low To Normalise' from the pico_pass column
  # The state of 'Too Low To Normalise' exists in the database (from SNP?)
  # but it doesn't look like AASM can handle spaces in state names.
  # assm_state :'Too Low To Normalise'

  # Since Pass and Fail are used as pico_state values we're forced
  # to use a different transition name.
  def pico_pass
    case self[:pico_pass]
    when 'Too Low To Normalise'
      'Fail'
    when nil, ''
      'ungraded'
    else
      self[:pico_pass]
    end
  end

  def measured_volume=(volume)
    self.initial_volume = volume
    self.current_volume = volume
    super
  end

  def estimated_volume
    (current_volume || measured_volume).try(:to_f)
  end

  def initial_volume=(volume)
    super if initial_volume.nil?
  end

  def quantity_in_nano_grams
    return nil if estimated_volume.nil? || concentration.nil?
    return 0 if estimated_volume < 0 || concentration < 0

    (estimated_volume * concentration).to_i
  end

  def quantity_in_micro_grams
    return nil if estimated_volume.nil? || concentration.nil?
    return 0 if estimated_volume < 0 || concentration < 0

    (estimated_volume * concentration) / 1000
  end

  def current_volume=(current_volume)
    current_volume = 0.0 if current_volume.to_f < 0
    super
  end

  def broadcast_warehouse_message
    message = Messenger.find_by(target_id: well_id)
    message.resend if message.present?
  end
end
