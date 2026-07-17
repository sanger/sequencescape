# frozen_string_literal: true
class RemoveRedundantUg200Descriptors < ActiveRecord::Migration[8.0]
  def up # rubocop:disable Metrics/AbcSize
    redundant_descriptor_names = [
      'OTR carrier Lot #',
      'OTR carrier expiry',
      'Reaction Mix 7 Lot #',
      'Reaction Mix 7 expiry',
      'NFW Lot #',
      'NFW expiry',
      'Oil Lot #',
      'Oil expiry',
      'Assign Control Bead Tube',
      'UG AMP Inst. Name'
    ]

    descriptors_to_remove = Workflow.find_by(name: 'Ultima UG200').tasks.flat_map(&:descriptors).select do |d|
      redundant_descriptor_names.include?(d.name)
    end

    if descriptors_to_remove.length != redundant_descriptor_names.length
      raise "Expected to find #{redundant_descriptor_names.length} descriptors to remove,
             but found #{descriptors_to_remove.length}. Aborting migration."
    end

    descriptors_to_remove.each(&:destroy!)
    Workflow.find_by(name: 'Ultima UG200').tasks.find_by(name: 'Amp').destroy

    # At time of writing there are no production batches that have any of these descriptors, so we are not removing
    # them from any existing lab events. The code below is commented out, but left in place in case it is needed in the
    # future.
    #
    # Get all sequencescape requests that might have any of the redundant descriptors
    # ug_200_seq_request_ids = UltimaUG200SequencingRequest.pluck(:id)
    # # Find lab events associated with those requests and remove the redundant descriptors from their descriptor hashes
    # LabEvent.where(eventful: ug_200_seq_request_ids, eventful_type: 'Request').find_each do |lab_event|
    #   lab_event.descriptor_hash.delete_if { |key, _value| redundant_descriptor_names.include?(key) }
    #   lab_event.save!
    # end
  end

  def down
    true
  end
end
