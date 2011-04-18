module CollectiveIdea::Acts::Audited::InstanceMethods
  private
    def write_audit(attrs)
      self.audits.create attrs if auditing_enabled && Audit.auditing_enabled?
    end
end

class Audit
  @@auditing_enabled = false
  def self.auditing_enabled?
    @@auditing_enabled
  end

  def self.disable_auditing
    @@auditing_enabled = false
  end

  def self.enable_auditing
    @@auditing_enabled = true
  end
end
