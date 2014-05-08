# There no subclasses at the moment, because we want to keep things simple
# # (especially no need to use a factory)
class FieldInfo
  SELECTION = 'Selection'
  TEXT      = 'Text'
  Kind      = [ SELECTION, TEXT ]
  attr_accessor :display_name, :key, :kind, :default_value, :parameters

  def initialize(args)
    self.display_name = args.delete(:display_name) || args.delete("display_name" )
    self.key = args.delete(:key) || args.delete("key")
    self.kind = args.delete(:kind) || args.delete("kind")
    self.default_value = args.delete(:default_value) || args.delete("default_value")
    params = args.delete(:parameters)  || args.delete("parameters")
    args.merge!(params) if params
    self.parameters= args
  end

  def old_initialize(display_name, key, kind, args = {})
    raise ArgumentError, "invalid field kind '#{kind}'" unless Kind.include?(kind)
    self.display_name = display_name
    self.key = key
    self.kind = kind
    self.default_value = args.delete(:default_value)
    self.parameters= args
  end

  def value
    return default_value || ""
  end

  # the following methods are Selection related. Move them in a subclass if needed
  def selection
    return nil unless kind == SELECTION
    return self.parameters[:selection]
  end

  def set_selection(selection)
    self.kind = SELECTION
    self.parameters[:selection] = selection
  end

  def reapply(object)
    value = nil
    value = object.send(self.key) unless object.nil? or self.key.blank?
    value ||= self.default_value
    self.default_value = value
  end
end
