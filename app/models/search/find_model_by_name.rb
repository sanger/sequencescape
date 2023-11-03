# frozen_string_literal: true
class Search::FindModelByName < Search
  validates :target_model_name, presence: true

  def model
    target_model_name.constantize
  end
  private :model

  def scope(criteria)
    model.with_name(criteria['name'])
  end
end
