# frozen_string_literal: true

module Tasks
  # While many {Task tasks} have handlers included directly
  # in the controller, we are attempting to move them out into
  # independent models. At times these may be more tightly coupled
  # to the controllers than is ideal, reflecting their previous
  # unity.
  class BaseHandler
    attr_reader :controller, :params, :task

    delegate :requests, to: :batch

    def initialize(controller:, params:, task:)
      @controller = controller
      @params = params
      @task = task
    end

    private

    # TODO: Pass this in instead
    def current_user
      controller.send(:current_user)
    end

    def create_batch_events
      event = batch.lab_events.build(description: 'Complete', user: current_user, batch: batch)
      event.add_descriptor Descriptor.new(name: 'task_id', value: task.id)
      event.add_descriptor Descriptor.new(name: 'task', value: task.name)
      event.save!
    end

    def selected_requests
      # Front end renders checkboxes in the form:
      # <input name="request[20251826]" id="sample 1 checkbox" class="sample_check select_all_target" value="on" type="checkbox" checked="">
      # We don't have hidden input fields of the same name, so params[:request] looks as follows:
      # { '123' => 'on', '124' => 'on' }
      # Unchecked requests are *not* listed in the hash.
      @selected_requests ||= params.fetch(:request, {}).keys.map(&:to_i)
    end
  end
end
