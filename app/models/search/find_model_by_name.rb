class Search::FindModelByName < Search
  validates_presence_of :target_model_name

  def model
    target_model_name.constantize
  end
  private :model

  def scope(criteria)
    model.with_name(criteria['name'])
  end
end
