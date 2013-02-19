Given /^(?:a|the) (project|study|sample|sample tube|library tube|plate|lane|pulldown multiplexed library tube|multiplexed library tube|faculty sponsor) (?:named|called) "([^\"]+)" exists$/ do |type,name|
  Factory(type.gsub(/[^a-z0-9]+/, '_').to_sym, :name => name)
end

Given /^(?:a|the) (well) (?:named|called) "([^\"]+)" exists$/ do |type,_|
  Factory(type.gsub(/[^a-z0-9]+/, '_').to_sym )
end

Given /^(?:a|the) properly created ((?:multiplexed )?library tube) (?:named|called) "([^\"]+)" exists$/ do |type, name|
  Factory(:"full_#{type.gsub(/[^a-z0-9]+/, '_')}", :name => name)
end

Given /^an (item) named "([^\"]+)" exists$/ do |type,name|
  Factory(type.gsub(/[^a-z0-9]+/, '_').to_sym, :name => name)
end

