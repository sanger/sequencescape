class Search::FindModelByName < Search
  validates_presence_of :model_name

  def model
    model_name.constantize
  end
  private :model

  def scope(criteria)
    model.with_name(criteria['name'])
  end
end
