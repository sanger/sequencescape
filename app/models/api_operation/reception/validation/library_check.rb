# frozen_string_literal: true

# Checks the library fields of the samples in the new labware, which go on
# their aliquots. Mirrors the sample manifest's library_type (and
# library_type_long_read, which sets the same field) and primer_panel
# fields: each names an existing library type or primer panel, ignoring case.
# An unknown name is reported once, at the first sample that uses it, with
# how many do; the names of each kind are looked up in one query.
# The schema already requires insert sizes to be whole numbers of at least 1,
# as the manifest does.
#
# Two rules the manifest doesn't have, as one of its columns can't
# contradict another:
# - insert_size_from is at most insert_size_to, when a sample gives both.
# - library_type and library_type_long_read are the same, ignoring case, when
#   a sample gives both.
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
      end + insert_size_errors + library_type_errors
  end

  private

  # An error for each sample whose insert size range is the wrong way round
  def insert_size_errors
    input.new_samples.filter_map do |sample|
      from, to = sample.fields.values_at('insert_size_from', 'insert_size_to')
      next unless from && to && from > to

      error("#{sample.pointer}/insert_size_to",
            "insert_size_to (#{to}) is less than insert_size_from (#{from})")
    end
  end

  # An error for each sample whose two library type fields differ
  def library_type_errors
    input.new_samples.filter_map do |sample|
      type, long_read =
        sample.fields.values_at('library_type', 'library_type_long_read')
      next unless type && long_read && type.casecmp(long_read).nonzero?

      error("#{sample.pointer}/library_type_long_read",
            "library_type_long_read (#{long_read}) differs from " \
            "library_type (#{type})")
    end
  end

  def unknown_name_errors(field, model, label)
    users_by_name(field).filter_map do |name, users|
      next if known_names(model).include?(name.downcase)

      error("#{users.first.pointer}/#{field}",
            "No #{label} named #{name} (#{used_by(users)})")
    end
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
