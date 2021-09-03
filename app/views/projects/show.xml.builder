# frozen_string_literal: true
xml.instruct!
xml.project(api_data) do
  xml.id @project.id
  xml.name @project.name
  xml.approved @project.approved
  xml.state @project.state
  xml.descriptors do
    @project
      .project_metadata
      .attribute_value_pairs
      .each do |attribute, value|
        xml.descriptor do
          xml.name attribute.to_field_info.display_name
          xml.value value
        end
      end
  end
end
