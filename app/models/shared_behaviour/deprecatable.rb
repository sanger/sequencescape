
module SharedBehaviour::Deprecatable
  def self.included(base)
    base.class_eval do
      scope :active, ->() { where(deprecated_at: nil) }
    end
  end

  def deprecate!
    self.deprecated_at = DateTime.now
    save!
  end

  # If we have a datestamp we are deprecated
  def deprecated?
    deprecated_at?
  end
end
