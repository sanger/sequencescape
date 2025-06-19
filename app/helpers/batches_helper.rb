# frozen_string_literal: true

# Helper associated with {Batch batches}
module BatchesHelper
  FAIL_LINK = 'Fail batch or requests'

  def purpose_for_labware(labware)
    labware.purpose&.name.presence || 'Unassigned'
  end

  #
  # Helps generate links for each action associated with a batch
  #
  # @param batch [Batch] The batch to generate links for
  # @yieldparam [String] name the name of the link to use for the action
  # @yieldparam [Hash,String] link A Url or hash object to use as the link's destination
  # @yieldparam [Boolean] enabled True if the link should be enabled
  # @yieldparam [String] message Message describing the link further, such as why it is disabled
  #
  # @return [Void]
  #
  def each_action(batch)
    batch.tasks&.each_with_index do |task, index|
      enabled, message = task.can_process?(batch)
      yield task.name, task_link(index, enabled, batch), enabled, message
    end
    yield(*fail_links(batch))
  end

  #
  # Generates a link for a given task index. Disabled links will have no explicit target
  #
  # @param index [Integer] The index of the {Task} to link to
  # @param enabled [Boolean] Whether the link is enabled or not
  # @param batch [Batch] The batch associated with the task
  #
  # @return [Hash,String] A hash or string with which to generate the link.
  #
  def task_link(index, enabled, batch)
    if enabled
      { controller: :workflows, action: :stage, id: index, batch_id: batch.id, workflow_id: batch.workflow.id }
    else
      '#'
    end
  end

  #
  # Generates a link to fail the batch if appropriate
  #
  # @param batch [Batch] The batch associated with the task
  #
  # @return [Hash,String] A hash or string with which to generate the link.
  #
  def fail_links(batch)
    if batch.pending?
      [FAIL_LINK, '#', false, 'Batches can not be failed when pending. Try reset batch under edit instead']
    else
      [FAIL_LINK, { action: :fail, id: batch.id }, true, nil]
    end
  end

  # Used by both assets/show.xml.builder and batches/show.xml.builder
  def output_aliquot(xml, aliquot) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    xml.sample(
      sample_id: aliquot.sample_id,
      library_id: aliquot.library_id,
      library_name: aliquot.library_name,
      library_type: aliquot.library_type,
      study_id: aliquot.study_id,
      project_id: aliquot.project_id,
      consent_withdrawn: aliquot.sample.consent_withdrawn?
    ) do
      # NOTE: XmlBuilder has a method called 'tag' so we have to say we want the element 'tag'!
      unless aliquot.tag.nil?
        xml.tag!(:tag, tag_id: aliquot.tag.id) do
          xml.index aliquot.aliquot_index_value || aliquot.tag.map_id
          xml.expected_sequence aliquot.tag.oligo
          xml.tag_group_id aliquot.tag.tag_group_id
        end
      end

      unless aliquot.tag2.nil?
        xml.tag(tag2_id: aliquot.tag2.id) do
          xml.expected_sequence aliquot.tag2.oligo
          xml.tag_group_id aliquot.tag2.tag_group_id
        end
      end

      xml.bait(id: aliquot.bait_library.id) { xml.name aliquot.bait_library.name } if aliquot.bait_library.present?

      xml.insert_size(from: aliquot.insert_size.from, to: aliquot.insert_size.to) if aliquot.insert_size.present?
    end
  end

  def batch_link(batch, options)
    link_text =
      tag.strong("Batch #{batch.id} ") << tag.span(batch.pipeline.name, class: 'pipline-name') << ' ' <<
      badge(batch.state, type: 'batch-state')
    link_to(link_text, batch_path(batch), options)
  end
end
