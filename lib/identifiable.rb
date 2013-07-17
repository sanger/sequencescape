module Identifiable
  def self.included(base)
    base.send(:has_many, :identifiers, :as => :identifiable)
    base.instance_eval do
      named_scope :with_identifier, lambda { |t| {
        :include => :identifiers,
        :conditions => { :identifiers => { :resource_name => t } }
      } }

      named_scope :sync_identifier, lambda { |t| {
        :joins => "INNER JOIN identifiers sid ON sid.identifiable_id=samples.id AND sid.identifiable_type IN (#{[self,*Class.subclasses_of(self)].map(&:name).map(&:inspect).join(',')})",
        :conditions => ['sid.resource_name=? AND NOT sid.do_not_sync AND sid.external_id IS NOT NULL', t]
      } }
    end
  end

  def identifier(resource_name)
    identifiers.detect { |i| i.resource_name == resource_name }
  end

  def set_external(resource_name, object_or_id)
    raise Exception.new, "Resource name can't be blank" if resource_name.blank?
    ident = identifier(resource_name) || identifiers.build(:resource_name => resource_name)
    if object_or_id.is_a? Fixnum
      ident.external_id = object_or_id
    else
      ident.external = object_or_id
    end
    ident.save
#    ident.save!
  end

  def external_id(resource_name)
    ident = identifier(resource_name)
    ident ? ident.external_id : nil
  end
  
  def external_object(resource_name)
    ident = identifier(resource_name)
    ident ? ident.external : nil
  end
  
end
