module ExternalResource
  ResourceName = "SNP"

  def self.included(base)
    base.send(:has_one, :identifier, :as => :external)
  end

  def set_identifiable(ident)
    ident.set_external(ResourceName, self)
  end

  alias identifiable= set_identifiable

  def identifiable
    identifier and identifier.identifiable
  end

  def identifiable_id
    identifier and identifier.identifiable.id
  end

end
