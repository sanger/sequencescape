# frozen_string_literal: true
module Pipeline::RequestsInStorage
  def ready_in_storage
    send((proxy_association.owner.group_by_parent ? :asset_on_labware : :all))
  end
end
