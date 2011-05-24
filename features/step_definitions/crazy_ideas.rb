Given /^the fields of the sample_metadata for the sample called "([^"]+)" are prepopulated$/ do |name|
  sample  = Sample.find_by_name(name) or raise StandardError, "Cannot find sample named #{name.inspect}"
  columns = sample.sample_metadata.class.content_columns
  updates = Hash[columns.map do |column|
    case
    when !sample.sample_metadata[column.name].nil? then nil
    when [ :string, :text ].include?(column.type)  then [ column.name, column.name ]
    when column.type == :boolean                   then true
    else raise StandardError, "Unknown column type #{column.type.inspect} (#{column.name.inspect})"
    end
  end.compact]
  sample.update_attributes!(:sample_metadata_attributes => updates)
end

