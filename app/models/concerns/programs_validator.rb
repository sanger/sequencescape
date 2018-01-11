class ProgramsValidator < ActiveModel::EachValidator

  PROGRAMS_LABELS = ['pcr 1', 'pcr 2']
  PROGRAMS_ATTRIBUTES = ['name', 'duration']

  def validate_each(record, attribute, value)
    value.each do |label, values|
      record.errors.add attribute, "invalid label #{label}" unless label.in?(PROGRAMS_LABELS)
      values.keys.each do |key|
        record.errors.add attribute, "invalid attribute #{key}" unless key.in?(PROGRAMS_ATTRIBUTES)
      end
    end
  end
end
