# frozen_string_literal: true
xml.instruct!
xml.families(api_data) do |families|
  if @tasks.empty?
    xml.comment!('There were no results returned. You might want to check your parameters if you expected any results.')
  else
    @tasks.each do |task|
      families.family do |family|
        family.id task.id
        family.name "#{task.workflow.name}: #{task.name}"
        family.description "#{task.workflow.name}: #{task.name}"
        family << '<relates-to></relates-to>'
      end
    end
  end
end
