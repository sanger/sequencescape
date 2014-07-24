module Tasks::ReferenceSequenceHandler
  def render_reference_sequence_task(task, params)
    @assets = task.find_batch_requests(params[:batch_id]).map{ |request| request.asset }.uniq
  end

  def do_reference_sequence_task(task, params)
    ActiveRecord::Base.transaction do
      params[:asset].each do |asset_id, protocol_id|
        protocol = ReferenceGenome.find(protocol_id).name
        if protocol.blank?
          flash[:warning] = 'All samples must have a protocol selected'
          return false
        end

        Asset.find(asset_id).pac_bio_library_tube_metadata.update_attributes!(:protocol => protocol)
      end
    end

    true
  end
end
