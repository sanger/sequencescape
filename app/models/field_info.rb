# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015,2016 Genome Research Ltd.

# There no subclasses at the moment, because we want to keep things simple
# # (especially no need to use a factory)
class FieldInfo
  SELECTION = 'Selection'
  TEXT      = 'Text'
  BOOLEAN   = 'Boolean'
  NUMERIC   = 'Numeric'
  Kind      = [SELECTION, TEXT, BOOLEAN]
  attr_accessor :display_name, :key, :kind, :default_value, :parameters

  def initialize(args)
    self.display_name = args.delete(:display_name) || args.delete('display_name')
    self.key = args.delete(:key) || args.delete('key')
    self.kind = args.delete(:kind) || args.delete('kind')
    self.default_value = args.delete(:default_value) || args.delete('default_value')
    params = args.delete(:parameters) || args.delete('parameters')
    args.merge!(params) if params
    self.parameters = args
  end

  def value
    default_value || ''
  end

  # the following methods are Selection related. Move them in a subclass if needed
  def selection
    return nil unless kind == SELECTION
    parameters[:selection]
  end

  def set_selection(selection)
    self.kind = SELECTION
    parameters[:selection] = selection
  end

  def reapply(object)
    value = nil
    value = object.send(key) unless object.nil? or key.blank?
    value ||= default_value
    self.default_value = value
  end
end
