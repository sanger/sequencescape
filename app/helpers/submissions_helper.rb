module SubmissionsHelper

  # Returns an array (or anything else) as an escaped string for
  # embedding in javascript
  def stringify_array(projects_array)
    projects_array.inspect
  end

  def order_input_label(field_info)
    label("submission[order_params][#{field_info.key}]", field_info.display_name)
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

  def order_selection_tag(field_info)
    select_tag(
      "submission[order_params][#{field_info.key}]",
      options_for_select(field_info.selection, field_info.value),
      :class => "required",
      :disabled => (field_info.selection.size == 1)
    )
  end
  private :order_selection_tag

  def order_text_tag(field_info)
    text_field_tag(
      "submission[order_params][#{field_info.key}]",
      field_info.value,
      :class => "required"
    )
  end
  private :order_text_tag


  def studies_select(studies)
    prompt = case studies.count
             when 0 then "You are not managing any Studies at this time"
             else "Please select a Study for this Submission..."
             end

    collection_select(
      :submission,
      :study_id,
      studies, :id, :name,
      { :prompt => prompt },
      { :disabled => true,
        :class => 'study_id' }
    )
  end

  def asset_group_select(asset_groups)
    prompt = case asset_groups.size
             when 0 then "There are no Asset Groups associcated with this Study"
             else 'Please select an asset group for this order.'
             end

    collection_select(
      :submission,
      :asset_group_id,
      asset_groups, :id, :name,
      { :prompt => prompt },
      {
        :class => 'asset_group_id required',
        :disabled => (asset_groups.size == 0)
      }
    )
  end
end
