# frozen_string_literal: true

# A {Task} used in the {SequencingPipeline sequencing pipelines}.
# Associates a tube of {SpikedBuffer} with a {Lane} indicating that PhiX has
# been added to the lane in question.
# @see Tasks::AddSpikedInControlHandler for behaviour included in the {WorkflowsController}
class AddSpikedInControlTask < Task
  # Holds information about a PhiX buffer for a given request in order to render the view.
  # - If indirect, will inform the user that PhiX has already been added, but will let them
  # override this with a deliberate click.
  # - To partial path is used by rails if you do `render object`, this lets us keep the logic
  #   outside of the views.
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

  def can_process?(batch)
    batch.released? ? [true, 'Edit'] : [true, nil]
  end

  def do_task(workflows_controller, params, user)
    Tasks::AddSpikedInControlHandler::Handler.new(controller: workflows_controller, params:, task: self, user:).perform
  end

  def fields_for(requests)
    if per_item_for(requests)
      requests.map { |request| phi_x_for(request.lane, request) }
    else
      phi_x_for(requests.first.lane, nil)
    end
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
