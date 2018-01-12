class ProgramsValidator < ActiveModel::EachValidator
  # attribute should be of the form:
  # {'pcr 1' => { 'name' => "pcr1 program", 'duration' => 45 },
  #  'pcr 2' => { 'name' => "pcr2 program" , 'duration' => 20 }}

  PROGRAMS_LABELS = ['pcr 1', 'pcr 2']
  PROGRAMS_PARAMS = ['name', 'duration']

  def validate_each(record, attribute, value)
    value.each do |program, params|
      record.errors.add attribute, "invalid label #{program}" unless program.in?(PROGRAMS_LABELS)
      params.keys.each do |key|
        record.errors.add attribute, "invalid attribute #{key}" unless key.in?(PROGRAMS_PARAMS)
      end
    end
  end
end
