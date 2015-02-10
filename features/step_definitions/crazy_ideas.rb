#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
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

