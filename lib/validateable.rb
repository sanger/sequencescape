# frozen_string_literal: true
module Validateable
  %i[save save! update_attribute].each { |attr| define_method(attr) {} }

  def method_missing(symbol, *_params)
    send($1) if symbol.to_s =~ /(.*)_before_type_cast$/
  end

  def self.append_features(base)
    super
    base.send(:include, ActiveModel::Validations)
    base.extend ClassMethods
  end

  def validate!
    raise(ActiveRecord::RecordInvalid, self) unless valid?
  end

  module ClassMethods
    def self_and_descendants_from_active_record
      [self]
    end

    def human_attribute_name(attribute_key_name, options = {})
      defaults =
        self_and_descendants_from_active_record.map do |klass|
          "#{klass.name.underscore}.#{attribute_key_name}" \
            "#{klass.name.underscore}.#{attribute_key_name}"
        end
      defaults << options[:default] if options[:default]
      defaults.flatten!
      defaults << attribute_key_name.to_s.humanize
      options[:count] ||= 1
      I18n.t(defaults.shift, **options, default: defaults, scope: %i[activerecord attributes])
    end

    def human_name(options = {})
      defaults =
        self_and_descendants_from_active_record.map do |klass|
          "#{klass.name.underscore}" \
            "#{klass.name.underscore}"
        end
      defaults << name.humanize
      I18n.t(defaults.shift, { scope: %i[activerecord models], count: 1, default: defaults }.merge(options))
    end
  end
end
