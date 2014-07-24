module Core::References
  # Discards all of the references that this object is keeping to other objects.  This means that
  # all of the objects should be garbage collected, rather than a proportion that are external to an
  # instance of this class.
  def discard_all_references
    instance_variables.each { |name| instance_variable_set(name, nil) }
  end
  private :discard_all_references
end
