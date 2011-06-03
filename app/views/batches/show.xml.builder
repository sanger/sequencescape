xml.instruct!
xml.batch {
  xml.id @batch.id
  xml.status @batch.state
  xml.lanes {
    @batch.ordered_requests.each do |request|
      xml.lane("position" => request.position(@batch)) {
        if request.asset.nil?
          xml.library("item_id" => request.item_id, "sample_id" => request.sample.id, "request_id" => request.id, "project_id" => request.project_id, "study_id" => request.study_id)
        elsif request.asset.resource?
          xml.control("id" => request.asset.id, "name" => request.asset.name, "request_id" => request.id)
        elsif request.asset.tags.map(&:tag).compact.empty?
          xml.library("id" => request.asset_id, "sample_id" => request.asset.sample_id, "name" => request.asset.name, "request_id" => request.id, "study_id" => request.study_id, "project_id" => request.project_id, "qc_state" => request.target_asset.compatible_qc_state)
        else
          xml.pool("id" => request.asset.id, "name" => request.asset.name, "request_id" => request.id, "study_id" => request.study_id, "project_id" => request.project_id, "qc_state" => request.target_asset.compatible_qc_state) {
            request.asset.tags.each do |library|
              xml.sample(:sample_id => library.sample.id,  :library_id => library.id) {
                # NOTE: XmlBuilder has a method called 'tag' so we have to say we want the element 'tag'!
                xml.tag!(:tag, :tag_id => library.tag.id) {
                  xml.index             library.tag.map_id
                  xml.expected_sequence library.tag.oligo
                  xml.tag_group_id      library.tag.tag_group_id
                } unless library.tag.nil?
              }
            end
          }
        end
          if request.target_asset && (hyb=request.target_asset.spiked_in_buffer)
            index = hyb.index

            xml.hyb_buffer("id" => hyb.id) {
              xml.control("id" => index.id, "name" => index.name) if index
              # NOTE: XmlBuilder has a method called 'tag' so we have to say we want the element 'tag'!
              xml.tag!(:tag, :tag_id => hyb.get_tag.id) {
                xml.index             hyb.get_tag.map_id
                xml.expected_sequence hyb.get_tag.oligo
                xml.tag_group_id      hyb.get_tag.tag_group_id
              } unless hyb.get_tag.nil?
            }
          end
      }
    end
  }
}
