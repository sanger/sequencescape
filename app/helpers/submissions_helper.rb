module SubmissionsHelper

  # Returns an array (or anything else) as an escaped string for
  # embedding in javascript
  def stringify_array(projects_array)
    projects_array.inspect
  end

  def order_input_label(field_info)
    label("submission[order][#{field_info.key}]", field_info.display_name)
  end

  # Returns a either a text input or a selection tag based on the 'kind'
  # of the order parameter passed in.
  # field_info is expected to be FieldInfo [sic]
  def order_input_tag(field_info)
    case field_info.kind
    when "Selection" then order_selection_tag(field_info)
    when "Text"      then order_text_tag(field_info)
    end
  end

  # TODO[sd9]: the form path probably needs to change here.  This tag is
  # based on the dodgy assumption that we'll creating one order per
  # time rather than using a collection...
  def order_selection_tag(field_info)
    select_tag(
      "submission[order][#{field_info.key}]",
      options_for_select(field_info.selection, field_info.value)
    )
  end
  private :order_selection_tag

  def order_text_tag(field_info)
    text_field_tag(
      "submission[order][#{field_info.key}]",
      field_info.value
    )
  end
  private :order_text_tag
end
