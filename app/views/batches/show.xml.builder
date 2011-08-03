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
          ) {
            request.asset.aliquots.each { |aliquot| output_aliquot(xml, aliquot) }
          }
        elsif request.asset.aliquots.map(&:tag).compact.empty?
          xml.library(
            "id"         => request.asset_id,
            "sample_id"  => request.asset.primary_aliquot.sample_id,
            "name"       => request.asset.name,
            "request_id" => request.id,
            "study_id"   => request.asset.primary_aliquot.study_id,
            "project_id" => request.asset.primary_aliquot.project_id,
            "qc_state"   => request.target_asset.compatible_qc_state
          ) {
            request.asset.aliquots.each { |aliquot| output_aliquot(xml, aliquot) }
          }
        else
          xml.pool(
            "id"         => request.asset.id,
            "name"       => request.asset.name,
            "request_id" => request.id,
            "study_id"   => request.study_id,
            "project_id" => request.project_id,
            "qc_state"   => request.target_asset.compatible_qc_state
          ) {
            request.asset.aliquots.each { |aliquot| output_aliquot(xml, aliquot) }
          }
        end

        if request.target_asset.present? and (hybridisation_buffer = request.target_asset.spiked_in_buffer)
          index, aliquot = hybridisation_buffer.index, hybridisation_buffer.primary_aliquot

          xml.hyb_buffer("id" => hybridisation_buffer.id) {
            xml.control("id" => index.id, "name" => index.name) if index.present?
            output_aliquot(xml, aliquot)
          }
        end
      }
    end
  }
}
