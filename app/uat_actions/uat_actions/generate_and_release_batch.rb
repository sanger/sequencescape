# frozen_string_literal: true

class UatActions::GenerateAndReleaseBatch < UatActions
  self.title = 'Generate and release batch'
  self.description = 'Create and release a sequencing batch.'
  self.category = :setup_and_test

  PIPELINE_OPTIONS = ['Ultima', 'Ultima UG200'].freeze

  form_field :tube_1_barcode,
             :text_field,
             label: 'Tube 1 Barcode',
             help: 'Enter the barcode of the first tube (mandatory).'
  form_field :tube_2_barcode,
             :text_field,
             label: 'Tube 2 Barcode',
             help: 'Enter the barcode of the second tube (mandatory).'
  form_field :pipeline_name,
             :select,
             label: 'Pipeline name',
             select_options: PIPELINE_OPTIONS,
             options: {
               include_blank: 'Select a pipeline from the list...'
             },
             help:
               'Select the sequencing pipeline for the batch (mandatory, must match valid sequencing requests on the ' \
               'tubes).'

  validates :tube_1_barcode, :tube_2_barcode, :pipeline_name, presence: true
  validates :pipeline_name, inclusion: { in: PIPELINE_OPTIONS }

  def perform
    tubes = find_tubes
    return false unless tubes

    pipeline = find_pipeline
    return false unless pipeline

    requests = find_requests(pipeline, tubes)
    return false unless requests

    batch = build_batch(pipeline, requests)
    return false unless batch

    release_batch(batch)
  end

  private

  def release_batch(batch)
    batch.release!(user)
    report[:batch_id] = batch.id
    report[:batch_state] = batch.state
    true
  end

  def find_tubes
    tubes = [tube_1_barcode, tube_2_barcode].each_with_index.map do |barcode, index|
      tube = Tube.find_by_barcode(barcode.to_s.strip)
      errors.add("tube_#{index + 1}_barcode", 'could not be found') unless tube
      tube
    end
    return if tubes.any?(&:nil?)

    tubes
  end

  def find_pipeline
    pipeline = Pipeline.find_by(name: pipeline_name)
    return pipeline if pipeline

    errors.add(:pipeline_name, 'could not be found')
    nil
  end

  def find_requests(pipeline, tubes)
    requests = tubes.map { |tube| pipeline.requests.inputs.find_by(asset_id: tube.receptacle.id) }
    requests.each_with_index do |request, index|
      errors.add(:base, "No pending request for Tube #{index + 1} was found in #{pipeline.name}.") unless request
    end
    return if requests.any?(&:nil?)

    requests
  end

  def build_batch(pipeline, requests)
    batch = pipeline.batches.build(requests:, user:)
    batch.skip_request_readiness_check = true
    return batch if batch.save

    errors.add(:base, batch.errors.full_messages.to_sentence)
    nil
  end

  def user
    UatActions::StaticRecords.user
  end
end
