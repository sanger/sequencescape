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

  def do_task(workflows_controller, params)
    Tasks::AddSpikedInControlHandler::Handler.new(controller: workflows_controller, params: params, task: self).perform
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
