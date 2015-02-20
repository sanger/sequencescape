#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014 Genome Research Ltd.
module BatchesHelper
  def purpose_for_plate(plate)
    if plate.plate_purpose.nil? || plate.plate_purpose.name.blank?
      "Unassigned"
    else
      plate.plate_purpose.name
    end
  end

  def fluidigm_plate(plate)
    plate.purpose.barcode_for_tecan == 'fluidigm_barcode'
  end

  # Used by both assets/show.xml.builder and batches/show.xml.builder
  def output_aliquot(xml, aliquot)
    xml.sample(
      :sample_id    => aliquot.sample.id,
      :library_id   => aliquot.library_id,
      :library_name => aliquot.library.try(:name),
      :library_type => aliquot.library_type,
      :study_id     => aliquot.study_id,
      :project_id   => aliquot.project_id,
      :consent_withdrawn => aliquot.sample.consent_withdrawn?
    ) {
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

  def workflow_name(batch)
    return unless batch and batch.workflow
    batch.workflow.name.gsub(/Cluster formation | \([^\)]*\)/,'')
  end
end
