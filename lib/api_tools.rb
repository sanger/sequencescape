#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.
module ApiTools
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def render_class
      @render_class ||= Api::Base.render_class_for_model(self)
    end
  end

  def for_api(options = {})
    self.class.render_class.to_hash(self)
  end

  def to_xml(options = {})
    renamed_keys = self.for_api.inject({}) do |renamed_keys,(key,value)|
      renamed_keys.tap { renamed_keys[key.underscore] = value }
    end
    options.reverse_merge!(:root => self.class.to_s.underscore, :skip_types => true)
    renamed_keys.to_xml(options)
  end

  def list_json(options = {})
    self.class.render_class.to_hash_for_list(self)
  end

  # TODO: Add relationships for object
  def as_json(options = {})
    { self.json_root => self.class.render_class.to_hash(self), 'lims'=>configatron.amqp.lims_id! }
  end

  def to_yaml(options = {})
    self.for_api.to_yaml(options)
  end

  def url_name
    self.class.to_s.underscore
  end
  alias_method(:json_root, :url_name)

  def url
    [ configatron.api_url, API_VERSION, self.url_name.pluralize, self.uuid ].join('/')
  end

end

class ActiveRecord::Base
  include ApiTools
end
