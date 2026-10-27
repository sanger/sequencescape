# frozen_string_literal: true

# Checks the library fields of the samples in the new labware, which go on
# their aliquots. Mirrors the sample manifest's library_type (and
# library_type_long_read, which sets the same field) and primer_panel
# fields: each names an existing library type or primer panel, ignoring case.
# An unknown name is reported once, at the first sample that uses it, with
# how many do; the names of each kind are looked up in one query.
# Insert sizes need no check here: the schema already requires whole numbers
# of at least 1, as the manifest does.
class ApiOperation::Reception::Validation::LibraryCheck <
      ApiOperation::Reception::Validation::Check
  # Each field, with the model it names a record of and how that is named in
  # messages
  FIELDS = {
    'library_type' => [::LibraryType, 'library type'],
    'library_type_long_read' => [::LibraryType, 'library type'],
    'primer_panel' => [::PrimerPanel, 'primer panel']
  }.freeze

  # (see ApiOperation::Reception::Validation::Check#errors)
  def errors
    @errors ||=
      FIELDS.flat_map do |field, (model, label)|
        unknown_name_errors(field, model, label)
      end
  end

  private

  def unknown_name_errors(field, model, label)
    users_by_name(field).filter_map do |name, users|
      next if known_names(model).include?(name.downcase)

      error("#{users.first.pointer}/#{field}",
            "No #{label} named #{name} (#{used_by(users)})")
    end
  end

  # The samples that give the field, by the name they give
  def users_by_name(field)
    input.new_samples.select { it.fields.key?(field) }
      .group_by { it.fields[field] }
  end

  # The model's names that the samples give, in lower case, looked up once
  def known_names(model)
    @known_names ||= {}
    @known_names[model] ||=
      model.where(name: names_of(model)).pluck(:name).to_set(&:downcase)
  end

  # The names the samples give in any of the model's fields
  def names_of(model)
    FIELDS.select { |_field, (field_model, _label)| field_model == model }
      .keys.flat_map { users_by_name(it).keys }
  end
end
