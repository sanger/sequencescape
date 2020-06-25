module BatchesHelper
  def purpose_for_labware(labware)
    labware.purpose&.name.presence || 'Unassigned'
  end

  # Used by both assets/show.xml.builder and batches/show.xml.builder
  def output_aliquot(xml, aliquot)
    xml.sample(
      sample_id: aliquot.sample_id,
      library_id: aliquot.library_id,
      library_name: aliquot.library_name,
      library_type: aliquot.library_type,
      study_id: aliquot.study_id,
      project_id: aliquot.project_id,
      consent_withdrawn: aliquot.sample.consent_withdrawn?
    ) {
      # NOTE: XmlBuilder has a method called 'tag' so we have to say we want the element 'tag'!
      xml.tag!(:tag, tag_id: aliquot.tag.id) {
        xml.index             aliquot.aliquot_index_value || aliquot.tag.map_id
        xml.expected_sequence aliquot.tag.oligo
        xml.tag_group_id      aliquot.tag.tag_group_id
      } unless aliquot.tag.nil?

      xml.tag(tag2_id: aliquot.tag2.id) {
        xml.expected_sequence aliquot.tag2.oligo
        xml.tag_group_id      aliquot.tag2.tag_group_id
      } unless aliquot.tag2.nil?

      xml.bait(id: aliquot.bait_library.id) {
        xml.name aliquot.bait_library.name
      } if aliquot.bait_library.present?

      xml.insert_size(from: aliquot.insert_size.from, to: aliquot.insert_size.to) if aliquot.insert_size.present?
    }
  end

  def workflow_name(batch)
    return unless batch and batch.workflow

    batch.workflow.name.gsub(/Cluster formation | \([^)]*\)/, '')
  end

  def batch_link(batch, options)
    link_text = tag.strong("Batch #{batch.id} ") <<
                tag.span(batch.pipeline.name, class: 'pipline-name') << ' ' <<
                badge(batch.state, type: 'batch-state')
    link_to(link_text, batch_path(batch), options)
  end
end
