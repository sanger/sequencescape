# frozen_string_literal: true
class ParentResource < JSONAPI::Resource
  def self.records(options = {})
    class_name = options[:_relation_helper_options][:join_manager].resource_klass
    class_name.to_s.demodulize.sub(/Resource$/, '').constantize.all
  end
end
