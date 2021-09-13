# frozen_string_literal: true
module ApiTools # rubocop:todo Style/Documentation
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods # rubocop:todo Style/Documentation
    def render_class
      @render_class ||= Api::Base.render_class_for_model(self)
    end
  end

  def for_api(_options = {})
    self.class.render_class.to_hash(self)
  end

  def to_xml(options = {})
    renamed_keys =
      for_api.inject({}) { |renamed_keys, (key, value)| renamed_keys.tap { renamed_keys[key.underscore] = value } }
    options.reverse_merge!(root: self.class.to_s.underscore, skip_types: true)
    renamed_keys.to_xml(options)
  end

  def list_json(_options = {})
    self.class.render_class.to_hash_for_list(self)
  end

  # TODO: Add relationships for object
  def as_json(_options = {})
    { json_root => self.class.render_class.to_hash(self), 'lims' => configatron.amqp.lims_id! }
  end

  def to_yaml(options = {})
    for_api.to_yaml(options)
  end

  def json_root
    self.class.to_s.underscore
  end
end

class ActiveRecord::Base
  include ApiTools
end
