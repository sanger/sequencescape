xml.instruct!
xml.batch {
  xml.id @batch.id
  xml.status @batch.state
  xml.lanes {
    @batch.ordered_requests.each do |request|
      xml.lane("position" => request.position(@batch)) {
#        # TODO: There are no requests without an asset, so these lines can go
#        if request.asset.nil?
#          xml.library("item_id" => request.item_id, "sample_id" => request.sample.id, "request_id" => request.id, "project_id" => request.project_id, "study_id" => request.study_id)
        if request.asset.resource?
          xml.control(
            "id"         => request.asset.id,
            "name"       => request.asset.name,
            "request_id" => request.id
          )
        elsif request.asset.aliquots.map(&:tag).compact.empty?
          xml.library(
            "id"         => request.asset_id,
            "sample_id"  => request.asset.primary_aliquot.sample_id,
            "name"       => request.asset.name,
            "request_id" => request.id,
            "study_id"   => request.primary_aliquot.study_id,
            "project_id" => request.primary_aliquot.project_id,
            "qc_state"   => request.target_asset.compatible_qc_state
          )
        else
          xml.pool(
            "id"         => request.asset.id,
            "name"       => request.asset.name,
            "request_id" => request.id,
            "study_id"   => request.study_id,
            "project_id" => request.project_id,
            "qc_state"   => request.target_asset.compatible_qc_state
          ) {
            request.asset.aliquots.each do |aliquot|
              xml.sample(:sample_id => aliquot.sample.id,  :library_id => aliquot.library_id, :study_id => aliquot.study_id, :project_id => aliquot.project_id) {
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
          }
        end

        if request.target_asset.present? and (hybridisation_buffer = request.target_asset.spiked_in_buffer)
          index, aliquot = hybridisation_buffer.index, hybridisation_buffer.primary_aliquot

          xml.hyb_buffer("id" => hybridisation_buffer.id) {
            xml.control("id" => index.id, "name" => index.name) if index.present?

            # NOTE: XmlBuilder has a method called 'tag' so we have to say we want the element 'tag'!
            xml.tag!(:tag, :tag_id => aliquot.tag.id) {
              xml.index             aliquot.tag.map_id
              xml.expected_sequence aliquot.tag.oligo
              xml.tag_group_id      aliquot.tag.tag_group_id
            } unless aliquot.tag.nil?
          }
        end
      }
    end
  }
}
