module SharedBehaviour::Deprecatable # rubocop:todo Style/Documentation
  def self.included(base)
    base.class_eval { scope :active, -> { where(deprecated_at: nil) } }
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
