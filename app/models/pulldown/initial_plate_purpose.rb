# Specialised implementation of the plate purpose for the initial plate types in the Pulldown pipelines:
# WGS Covaris, SC Covaris, ISC Covaris.
class Pulldown::InitialPlatePurpose < PlatePurpose
  def transition_to(plate, state, contents = nil,customer_accepts_responsibility=false)
    ActiveRecord::Base.transaction do
      super
      new_outer_state = ['started','passed','qc_complete','nx_in_progress'].include?(state) ? 'started' : state
      outer_requests(plate,contents).each do |request|
        # request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(new_outer_state) if request.pending?
      end
    end
  end

  def outer_requests(plate,contents)
    well_ids = contents.present? ? plate.wells.located_at(contents).map(&:id) : plate.wells.map(&:id)
    transfer_request_sti = [TransferRequest, *Class.subclasses_of(TransferRequest)].map(&:name).map(&:inspect).join(',')
    Request.find(:all, {
      :select => "requests.*",
      :joins => [
        "INNER JOIN requests AS asctf ON asctf.asset_id = requests.asset_id AND asctf.sti_type IN (#{transfer_request_sti})"
      ],
      :conditions => ["asctf.target_asset_id IN (?) AND NOT requests.sti_type IN (#{transfer_request_sti})", plate.wells.map(&:id)]
      })
  end
end
