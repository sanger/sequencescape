module BatchesHelper # rubocop:todo Style/Documentation
  def purpose_for_labware(labware)
    labware.purpose&.name.presence || 'Unassigned'
  end

  def each_action(batch) # rubocop:todo Metrics/MethodLength
    batch.tasks&.each_with_index do |task, index|
      enabled, message = task.can_process?(batch)
      link =
        if enabled
          { controller: :workflows, action: :stage, id: index, batch_id: batch.id, workflow_id: batch.workflow.id }
        else
          '#'
        end
      yield task.name, link, enabled, message
    end
    yield(*fail_links(batch))
  end

  def fail_links(batch)
    if batch.pending?
      [
        'Fail batch or requests',
        '#',
        false,
        'Batches can not be failed when pending. Try reset batch under edit instead'
      ]
    else
      ['Fail batch or requests', { action: :fail, id: batch.id }, true, nil]
    end
  end

  # Used by both assets/show.xml.builder and batches/show.xml.builder
  def output_aliquot(xml, aliquot) # rubocop:todo Metrics/AbcSize
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
