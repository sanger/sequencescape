class Metadata::FormBuilder < Metadata::BuilderBase # rubocop:todo Style/Documentation
  def initialize(*args, &block)
    super
    view_for(:field, 'shared/metadata/edit_field')
    view_for(:radio_field, 'shared/metadata/radio_field')
    view_for(:header, 'shared/metadata/header')
    view_for(:document, 'shared/metadata/edit_document_field')

    @related_fields, @changing = [], []
  end

  # Creates a file upload field that will be properly handled by Document instances.  It's a bit of
  # a hack because the field we're actually rendering is not what is requested in 'field', but
  # 'field_attributes[uploaded_data]', so we have to also use a special view for it to alter that.
  #--
  # NOTE: This is immediately overridden by the block below so don't move it!
  #++
  def document_field(field, options)
    property_field(:document, field, options) do
      fields_for(:"#{field}_attributes", builder: ActionView::Helpers::FormBuilder) do |fields|
        fields.file_field(:uploaded_data)
      end
    end
  end

  def select_by_association(association, options = {}, html_options = {})
    html_options[:class] ||= 'select2'
    association_target = association.to_s.classify.constantize
    if @object.send(association).nil? && association_target.default.present?
      options[:selected] = association_target.default.for_select_dropdown.last
    end
    select(:"#{association}_id", association_target.for_select_association, options, html_options)
  end

  %i[text_area text_field number_field].each do |field|
    class_eval <<-END_OF_METHOD
      def #{field}_with_bootstrap(*args, &block)
        options    = args.extract_options!
        options[:class] ||= ''
        options[:class] << ' form-control'
        args.push(options)
        #{field}_without_bootstrap(*args, &block)
      end
    END_OF_METHOD
    alias_method("#{field}_without_bootstrap", field)
    alias_method(field, "#{field}_with_bootstrap")
  end

  def select(method, choices, options = {}, html_options = {}, &block)
    group = html_options.delete(:grouping) || options.delete(:grouping)
    html_options[:class] ||= ''
    html_options[:class] << ' custom-select'
    property_field(:field, method, grouping: group) { super(method, choices, options, html_options, &block) }
  end

  def radio_select(method, choices, options = {}, html_options = {})
    group = html_options.delete(:grouping) || options.delete(:grouping)
    property_field(:radio_field, method, grouping: group) do
      choices.each_with_object(+''.html_safe) do |(label_text, option_value), output|
        output << tag.div(class: %w[custom-control custom-radio custom-control-inline]) do
          value = option_value || label_text
          concat radio_button(method, value, class: 'custom-control-input', required: true)
          concat label(method, label_text, class: 'custom-control-label', value: value)
        end
      end
    end
  end

  # We wrap each of the following field types (text_field, select, etc) within a special
  # layout for our properties
  #
  %i[text_area text_field number_field file_field check_box].each do |field|
    class_eval do
      define_method field do |method, *args, &block|
        options = args.extract_options!
        options[:class] ||= []
        options[:class] << ' form-control'
        field_args = options.slice(:grouping)
        args.push(options.slice!(:grouping))
        property_field(:field, method, field_args) { super(method, *args, &block) }
      end
    end
  end

  def header(field, options = {})
    render_view(:header, field, options)
  end

  # Handles wrapping certain fields so that they are only shown when another field is a certain value.
  # You can use `:to` to give the name of the field, `:when` for the single value when the fields should
  # be shown, and `:in` for a group of values.  You *must* call finalize_related_fields at the end of
  # your view to get the appropriate behaviour
  def related_fields(options, &block) # rubocop:todo Metrics/AbcSize
    options.symbolize_keys!

    values =
      (options.fetch(:in, Array(options[:when])) - Array(options[:not])).map do |v|
        v.to_s.downcase.gsub(/[^a-z0-9]+/, '_')
      end
    content = capture(&block)
    concat(tag.div(content, class: [:related_to, options[:to], values].flatten.join(' ')))

    @related_fields.push(options[:to])
    content
  end

  # Allows the options of the specified 'field' to be changed based on the value of another field.
  def change_select_options_for(field, options)
    options[:values] =
      options[:values].inject({}) do |values, (key, value)|
        values.tap { Array(key).each { |k| values[k.to_s] = Array(value) } }
      end
    @changing.push([field, options])
  end

  # Renders the Javascript for dealing with showing and hiding the related fields.
  def finalize_related_fields
    related = @related_fields.compact.uniq.map(&:to_s)
    unless related.empty?
      concat(
        render(
          partial: 'shared/metadata/related_fields',
          locals: {
            root: sanitized_object_name,
            related: related,
            changing_fields: @changing
          }
        )
      )
    end
  end

  private

  def property_field(type, field, options = {})
    content = capture { render_view(type, field, options) { |locals| locals.merge(field: yield) } }

    div_options = { id: field.to_s }
    div_options[:class] = 'field_with_errors' if @object.errors[field].present?
    tag.fieldset(content, div_options)
  end
end
