module Pipeline::RequestsInStorage
  def ready_in_storage
    send((proxy_owner.group_by_parent ? :holder_located : :located), proxy_owner.location_id)
  end
end
