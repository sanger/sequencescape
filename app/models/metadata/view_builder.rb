class Metadata::ViewBuilder < Metadata::BuilderBase
  def initialize(*args, &block)
    super
    view_for(:plain_value, 'shared/metadata/plain_field')
    view_for(:file, 'shared/metadata/file')
  end

  def plain_value(field, options = {})
    render_view(:plain_value, field, options) { |locals| locals.merge(:value => @object.send(field)) }
  end

  def yes_or_no(field, options = {})
    render_view(:plain_value, field, options) { |locals| locals.merge(:value => @object.send(field).present? ? "Yes" : "No") }
  end

  def file(field, options = {})
    render_view(:file, field, options) { |locals| locals.merge(:document => @object.send(field)) }
  end

  def association_attribute(association_name, attribute, options = {})
    render_view(:plain_value, :"#{association_name}_id", options) { |locals| locals.merge(:value => @object.try(association_name).try(attribute)) }
  end
end
