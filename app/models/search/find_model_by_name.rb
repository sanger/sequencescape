class Search::FindModelByName < Search # rubocop:todo Style/Documentation
  validates :target_model_name, presence: true

  def model
    target_model_name.constantize
  end
  private :model

  def scope(criteria)
    model.with_name(criteria['name'])
  end
end
