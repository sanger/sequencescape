# frozen_string_literal: true

# A {Task} used in the {SequencingPipeline sequencing pipelines}.
# Associates a tube of {SpikedBuffer} with a {Lane} indicating that PhiX has
# been added to the lane in question.
# @see Tasks::AddSpikedInControlHandler for behaviour included in the {WorkflowsController}
class AddSpikedInControlTask < Task
  def partial
    'add_spiked_in_control'
  end

  def can_process?(batch, from_previous: false) # rubocop:disable Lint/UnusedMethodArgument
    batch.released? ? [true, 'Edit'] : [true, nil]
  end

  def do_task(controller, params)
    controller.do_add_spiked_in_control_task(self, params)
  end

  def add_control(batch, phi_x_tube, request_id_set)
    return false unless batch && phi_x_tube

    batch.requests.each do |request|
      next unless request_id_set.include? request.id

      lane = request.target_asset.labware
      next unless lane
      lane.direct_spiked_in_buffer = nil
      lane.parents << phi_x_tube
    end

    batch.save
    true
  end
end
