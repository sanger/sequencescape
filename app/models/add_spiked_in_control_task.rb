# frozen_string_literal: true

# A {Task} used in the {SequencingPipeline sequencing pipelines}.
# Associates a tube of {SpikedBuffer} with a {Lane} indicating that PhiX has
# been added to the lane in question.
# @see Tasks::AddSpikedInControlHandler for behaviour included in the {WorkflowsController}
class AddSpikedInControlTask < Task
  def partial
    'add_spiked_in_control'
  end

  def do_task(controller, params)
    controller.do_add_spiked_in_control_task(self, params)
  end

  def add_control(batch, control_asset, request_id_set)
    return false unless batch && control_asset

    batch.requests.each do |request|
      next unless request_id_set.include? request.id

      lane = request.target_asset
      next unless lane

      AssetLink.create_edge(control_asset, lane)
    end

    control_asset.save!
    true
  end
end
