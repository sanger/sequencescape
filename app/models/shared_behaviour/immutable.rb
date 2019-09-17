module SharedBehaviour::Immutable
  MUTABLE = %w[deprecated_at updated_at].freeze

  def self.included(base)
    base.class_eval do
      before_update :save_allowed?
    end
  end

  private

  def save_allowed?
    return true if (changed - MUTABLE).empty?

    raise ActiveRecord::RecordNotSaved, 'This record is immutable. Deprecate it and create a replacement instead.'
  end
end
