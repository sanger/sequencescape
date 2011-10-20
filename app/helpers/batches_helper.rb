module BatchesHelper
  def purpose_for_plate(plate)
    if plate.plate_purpose.nil? || plate.plate_purpose.name.blank?
      "Unassigned"
    else
      plate.plate_purpose.name
    end
  end

  # Used by both assets/show.xml.builder and batches/show.xml.builder
  def output_aliquot(xml, aliquot)
    xml.sample(
      :sample_id    => aliquot.sample.id,
      :library_id   => aliquot.library_id,
      :library_name => aliquot.library.try(:name),
      :study_id     => aliquot.study_id,
      :project_id   => aliquot.project_id
    ) {
      # Expose the library information for this aliquot
      xml.library(:id => aliquot.library_id) {
        xml.name(aliquot.library.name) if aliquot.library.present?
        xml.type(aliquot.library_type) if aliquot.library_type.present?
      }

      # NOTE: XmlBuilder has a method called 'tag' so we have to say we want the element 'tag'!
      xml.tag!(:tag, :tag_id => aliquot.tag.id) {
        xml.index             aliquot.tag.map_id
        xml.expected_sequence aliquot.tag.oligo
        xml.tag_group_id      aliquot.tag.tag_group_id
      } unless aliquot.tag.nil?

      xml.bait(:id => aliquot.bait_library.id) {
        xml.name aliquot.bait_library.name
      } if aliquot.bait_library.present?

      xml.insert_size(:from => aliquot.insert_size.from, :to => aliquot.insert_size.to) if aliquot.insert_size.present?
    }
  end
end
