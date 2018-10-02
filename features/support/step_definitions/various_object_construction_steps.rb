Given /^(?:a|the) (project|study|sample|sample tube|library tube|plate|lane|pulldown multiplexed library tube|multiplexed library tube|faculty sponsor) (?:named|called) "([^\"]+)" exists$/ do |type, name|
  FactoryBot.create(type.gsub(/[^a-z0-9]+/, '_').to_sym, name: name)
end

Given /^(?:a|the) (well) (?:named|called) "([^\"]+)" exists$/ do |type, _|
  FactoryBot.create(type.gsub(/[^a-z0-9]+/, '_').to_sym)
end
