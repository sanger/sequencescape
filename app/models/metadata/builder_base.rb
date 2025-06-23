# frozen_string_literal: true
class Metadata::BuilderBase < ActionView::Helpers::FormBuilder
  attr_writer :locals

  def initialize(*args, &)
    super
    @views, @locals, @root = {}, {}, nil
  end

  def view_for(type, partial_name = nil, &)
    @views[type.to_sym] = partial_name.nil? ? { inline: capture(&) } : { partial: partial_name }
  end

  private

  delegate :concat, :capture, :render, :content_tag, :tag, to: :@template

  #--
  # NOTE: Ripped directly from InstanceTag in form_helper.rb
  #++
  def sanitized_object_name
    @object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/, '_').sub(/_$/, '')
  end

  def localised_sections(field)
    sections = @object.class.localised_sections(field).dup
    required_fields = %i[ebi_library_strategy ebi_library_source ebi_library_selection]
    if @object.required?(field) || (@object.new_record? && required_fields.include?(field))
      sections.label_options = { class: 'required' }
    end
    sections
  end

  def render_view(type, field, options = {})
    view = @views.fetch(type.to_sym)

    locals =
      @locals.merge(
        sections: localised_sections(field),
        form: self,
        field_name: field,
        group: nil,
        value: @object.send(field)
      )
    locals[:group] = options[:grouping].downcase.gsub(/[^a-z0-9]+/, '_') if options[:grouping].present?
    locals = yield(locals) if block_given?
    render(view.merge(locals:))
  end
end
