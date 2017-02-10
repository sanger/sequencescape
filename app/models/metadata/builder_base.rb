# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Metadata::BuilderBase < ActionView::Helpers::FormBuilder
  attr_writer :locals

  def initialize(*args, &block)
    super
    @views, @locals, @root, @filter = {}, {}, nil, ->(_) { true }
  end

  def view_for(type, partial_name = nil, &block)
    @views[type.to_sym] =
      if partial_name.nil?
        { inline: capture(&block) }
      else
        { partial: partial_name }
      end
  end

  def filter(&block)
    @filter = block
  end

private

  delegate :concat, :capture, :render, :content_tag, to: :@template

  #--
  # NOTE: Ripped directly from InstanceTag in form_helper.rb
  #++
  def sanitized_object_name
    @object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/, '_').sub(/_$/, '')
  end

  def localised_sections(field)
    sections = @object.class.localised_sections(field).dup
    sections.label_options = { class: 'required' } if @object.required?(field)
    sections
  end

  def render_view(type, field, options = {})
    return nil unless @filter.call(@object.class.metadata_attribute_path(field))
    view   = @views[type.to_sym] or raise StandardError, "View not registered for '#{type}'"

    locals = @locals.merge(
      sections: localised_sections(field),
      form: self,
      field_name: field,
      group: nil,
      value: @object.send(field)
    )
    locals[:group] = options[:grouping].downcase.gsub(/[^a-z0-9]+/, '_') unless options[:grouping].blank?
    locals = yield(locals) if block_given?

    render(view.merge(locals: locals))
  end
end
