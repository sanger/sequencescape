module Pipeline::RequestsInStorage
  def ready_in_storage
    send((proxy_association.owner.group_by_parent ? :holder_located : :all))
  end
end
