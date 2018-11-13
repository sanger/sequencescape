# Specialised implementation of the plate purpose for the initial plate types in the Pulldown pipelines:
# WGS Covaris, SC Covaris, ISC Covaris.
class Pulldown::InitialPlatePurpose < PlatePurpose
  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    ActiveRecord::Base.transaction do
      super
      new_outer_state = ['started', 'passed', 'qc_complete'].include?(state) ? 'started' : state
      outer_requests(plate, contents).each do |request|
        # request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(new_outer_state) if request.pending?
      end
    end
  end

  def outer_requests(plate, contents)
    well_ids = contents.present? ? plate.wells.located_at(contents).pluck(:id) : plate.wells.pluck(:id)
    Request.select('requests.*')
           .joins('INNER JOIN transfer_requests ON transfer_requests.asset_id = requests.asset_id')
           .where(transfer_requests: { target_asset_id: well_ids })
  end
end
