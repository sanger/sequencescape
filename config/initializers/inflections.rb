# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

ActiveSupport::Inflector.inflections(:en) do |inflect| 
  inflect.uncountable %w[health sample_metadata labware]
  inflect.acronym "AASM"
end

# Create inflections so all files ending up with _io will be inflected
# as IO (this is because zeitwerk has changed inflections of upper cases
# in rails 6.1.
# <https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#customizing-inflections
ALL_IO_FILES = Dir["**/*_io.rb"].map{|name| File.basename(name)}
custom_io_inflections = ALL_IO_FILES.reduce({}) do |memo, name|
  # Name without the final _io. Eg: flowcell
  partial_name = name.gsub(/_io\.rb/,'') 
  # Name with the _io. Eg: flocell_io
  basic_name = "#{partial_name}_io" 
  # Camelized name with IO. Eg: FlowcellIO
  camelized_name = "#{partial_name.camelize}IO" 
  memo[basic_name] = camelized_name
  memo
end

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(custom_io_inflections)
end  

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end
