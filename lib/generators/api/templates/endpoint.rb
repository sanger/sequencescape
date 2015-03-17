#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class ::Endpoints::<%= plural_name.camelize %> < ::Core::Endpoint::Base
  model do

<% if can_create? -%>
    action(:create) do |request, response|
      request.create!
    end
<% end -%>
  end

  instance do
<% belongs_to_associations.each do |name, options| -%>
    belongs_to(<%= name.to_sym.inspect %>, <%= options.map { |k,v| "#{k.inspect} => #{v.inspect}" }.join(', ') %>)
<% end -%>
<% has_many_associations.each do |name, options| -%>
    has_many(<%= name.to_sym.inspect %>, <%= options.map { |k,v| "#{k.inspect} => #{v.inspect}" }.join(', ') %>)
<% end -%>

<% if can_update? -%>
    action(:update) do |request, response|
      request.update!
    end
<% end -%>
  end
end
