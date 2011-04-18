module Validateable

  [:save, :save!, :update_attribute].each{|attr| define_method(attr){}}

  def method_missing(symbol, *params)
    if(symbol.to_s =~ /(.*)_before_type_cast$/)
      send($1)
    end
  end

  def self.append_features(base)
    super
    base.send(:include, ActiveRecord::Validations)
    base.extend ClassMethods

    base.send :include, ActiveSupport::Callbacks
    base.define_callbacks *ActiveRecord::Validations::VALIDATIONS

  end

  def validate!
    raise ActiveRecord::RecordInvalid, self unless valid?
  end

  module ClassMethods
    def self_and_descendants_from_active_record
      [self]
    end
    def human_attribute_name(attribute_key_name, options = {})
      defaults = self_and_descendants_from_active_record.map do |klass|
        "#{klass.name.underscore}.#{attribute_key_name}""#{klass.name.underscore}.#{attribute_key_name}"
      end
      defaults << options[:default] if options[:default]
      defaults.flatten!
      defaults << attribute_key_name.humanize
      options[:count] ||= 1
      I18n.translate(defaults.shift, options.merge(:default => defaults, :scope => [:activerecord, :attributes]))
    end
    def human_name(options = {})
      defaults = self_and_descendants_from_active_record.map do |klass|
        "#{klass.name.underscore}""#{klass.name.underscore}"
      end
      defaults << self.name.humanize
      I18n.translate(defaults.shift, {:scope => [:activerecord, :models], :count => 1, :default => defaults}.merge(options))
    end
  end

end
