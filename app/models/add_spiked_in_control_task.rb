# frozen_string_literal: true

# A {Task} used in the {SequencingPipeline sequencing pipelines}.
# Associates a tube of {SpikedBuffer} with a {Lane} indicating that PhiX has
# been added to the lane in question.
# @see Tasks::AddSpikedInControlHandler for behaviour included in the {WorkflowsController}
class AddSpikedInControlTask < Task
  SpikedBufferRecord =
    Struct.new(:barcode, :indirect, :request) do
      def to_partial_path
        indirect ? 'indirect_phi_x_fields' : 'direct_phi_x_fields'
      end

      def label
        request ? "Request #{request.position} : #{request.asset.display_name} PhiX Barcode" : 'PhiX Barcode'
      end
    end

  def partial
    'add_spiked_in_control'
  end

  def can_process?(batch, from_previous: false)
    batch.released? ? [true, 'Edit'] : [true, nil]
  end

  def do_task(controller, params)
    controller.do_add_spiked_in_control_task(self, params)
  end

  def add_control(batch, phi_x_per_request, request_id_set, current_user)
    batch.requests.each do |request|
      next unless request_id_set.include? request.id

      process_request(batch, phi_x_per_request, request, current_user)
    end

    batch.save!
    batch.requests.all? { |r| r.has_passed(batch, self) }
  end

  def process_request(batch, phi_x_per_request, request, current_user)
    lane = request.target_asset.labware
    phi_x_tube = phi_x_per_request[request.id.to_s] || phi_x_per_request[:all]
    return unless lane # JG: I *think* this may be to handle control requests?
    lane.direct_spiked_in_buffer = nil
    lane.direct_spiked_in_buffer = phi_x_tube if phi_x_tube
    LabEvent.create!(
      batch: batch,
      description: name,
      descriptors: descriptors_for(phi_x_tube),
      user: current_user,
      eventful: request
    )
  end

  def descriptors_for(phi_x_tube)
    if phi_x_tube
      {
        'PhiX added' => true,
        'Scanned PhiX' => phi_x_tube.human_barcode,
        'PhiX Stock Barcode' => phi_x_tube.parent&.human_barcode
      }
    else
      { 'PhiX added' => false }
    end
  end

  def fields_for(requests)
    per_item_for(requests) ? requests.map { |r| phi_x_for(r.lane, r) } : phi_x_for(requests.first.lane, nil)
  end

  # Returns true if we should collect descriptors per request.
  # Always true if {#per_item} is true, otherwise true if requests have different
  # values
  def per_item_for(requests)
    per_item || requests.map { |request| phi_x_for(request.lane, nil) }.uniq.many?
  end

  def phi_x_for(lane, request)
    if lane.direct_spiked_in_buffer
      SpikedBufferRecord.new(lane.direct_spiked_in_buffer.machine_barcode, false, request)
    elsif lane.most_recent_spiked_in_buffer
      SpikedBufferRecord.new(lane.most_recent_spiked_in_buffer.machine_barcode, true, request)
    else
      SpikedBufferRecord.new(nil, false, request)
    end
  end
end
