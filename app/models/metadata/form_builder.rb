# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class Metadata::FormBuilder < Metadata::BuilderBase
  def initialize(*args, &block)
    super
    view_for(:field, 'shared/metadata/edit_field')
    view_for(:header, 'shared/metadata/header')
    view_for(:document, 'shared/metadata/edit_document_field')
    view_for(:checktext, 'shared/metadata/edit_checktext_field')

    @related_fields, @changing = [], []
  end

  # Creates a file upload field that will be properly handled by Document instances.  It's a bit of
  # a hack because the field we're actually rendering is not what is requested in 'field', but
  # 'field_attributes[uploaded_data]', so we have to also use a special view for it to alter that.
  #--
  # NOTE: This is immediately overridden by the block below so don't move it!
  #++
  def document_field(field, _options = {})
    fields_for(:"#{ field }_attributes", builder: ActionView::Helpers::FormBuilder) do |fields|
      fields.file_field(:uploaded_data)
    end
  end

  def select_by_association(association, options = {}, html_options = {})
    association_target, options = association.to_s.classify.constantize, {}
    options[:selected] = association_target.default.for_select_dropdown.last if @object.send(association).nil? and association_target.default.present?
    select(:"#{association}_id", association_target.for_select_association, options, html_options)
  end

  def checktext_field(field, options = {})
    render_view(:checktext, field, options)
  end

  [:text_area, :text_field, :number_field].each do |field|
    class_eval <<-END_OF_METHOD
      def #{field}_with_bootstrap(*args, &block)
        options    = args.extract_options!
        options[:class] ||= ''
        options[:class] << ' form-control'
        args.push(options)
        #{field}_without_bootstrap(*args, &block)
      end
    END_OF_METHOD
    alias_method_chain(field, :bootstrap)
  end

  def select_with_bootstrap(method, choices, options = {}, html_options = {}, &block)
    html_options[:class] ||= ''
    html_options[:class] << ' form-control'
    select_without_bootstrap(method, choices, options, html_options, &block)
  end
  alias_method_chain(:select, :bootstrap)

  # We wrap each of the following field types (text_field, select, etc) within a special
  # layout for our properties
  #
  {
    document_field: :document,
    text_area: :field,
    text_field: :field,
    number_field: :field,
    select: :field,
    file_field: :field,
    check_box: :field,
    checktext_field: :field
  }.each do |field, type|
    class_eval <<-END_OF_METHOD
      def #{field}_with_property_field_wrapper(method, *args, &block)
        options    = args.extract_options!
        field_args = options.slice(:grouping)
        args.push(options.slice!(:grouping))
        property_field(#{type.inspect}, method, field_args) do
          #{field}_without_property_field_wrapper(method, *args, &block)
        end
      end
    END_OF_METHOD
    alias_method_chain(field, :property_field_wrapper)
  end

  def header(field, options = {})
    render_view(:header, field, options)
  end

  # Handles wrapping certain fields so that they are only shown when another field is a certain value.
  # You can use `:to` to give the name of the field, `:when` for the single value when the fields should
  # be shown, and `:in` for a group of values.  You *must* call finalize_related_fields at the end of
  # your view to get the appropriate behaviour
  def related_fields(options, &block)
    options.symbolize_keys!

    values  = (options.fetch(:in, Array(options[:when])) - Array(options[:not])).map { |v| v.to_s.downcase.gsub(/[^a-z0-9]+/, '_') }
    content = capture(&block)
    concat(content_tag(:div, content, class: [:related_to, options[:to], values].flatten.join(' ')))

    @related_fields.push(options[:to])
    content
  end

  # Allows the options of the specified 'field' to be changed based on the value of another field.
  def change_select_options_for(field, options)
    options[:values] = options[:values].inject({}) do |values, (key, value)|
      values.tap do
        Array(key).each { |k| values[k.to_s] = Array(value) }
      end
    end
    @changing.push([field, options])
  end

  # Renders the Javascript for dealing with showing and hiding the related fields.
  def finalize_related_fields
    related = @related_fields.compact.uniq.map(&:to_s)
    concat(render(
      partial: 'shared/metadata/related_fields',
      locals: {
        root: sanitized_object_name,
        related: related,
        changing_fields: @changing
      }
    )) unless related.empty?
  end

private

  def property_field(type, field, options = {})
    content = capture do
      render_view(type, field, options) { |locals| locals.merge(field: yield) }
    end

    div_options = { id: field.to_s }
    (div_options[:class] ||= []) << 'field_with_errors' unless @object.errors.get(field).blank?
    content_tag(:div, content, div_options)
  end
end
