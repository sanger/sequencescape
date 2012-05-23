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
  def order_input_tag(order, field_info)
    case field_info.kind
    when "Selection" then order_selection_tag(order, field_info)
    when "Text"      then order_text_tag(order, field_info)
    end
  end

  def order_selection_tag(order, field_info)
    select_tag(
      "submission[order_params][#{field_info.key}]",
      options_for_select(
        field_info.selection.map(&:to_s),
        order.request_options.try(:[], field_info.key)
      ),
      :class => "required",
      :disabled => (field_info.selection.size == 1)
    )
  end
  private :order_selection_tag

  def order_text_tag(order, field_info)
    text_field_tag(
      "submission[order_params][#{field_info.key}]",
      order.request_options.try(:[], field_info.key) || field_info.default_value,
      :class => "required"
    )
  end
  private :order_text_tag


  def studies_select(form, studies)
    prompt = case studies.count
             when 0 then "You are not managing any Studies at this time"
             else "Please select a Study for this Submission..."
             end

    form.collection_select(
      :study_id,
      studies, :id, :name,
      { :prompt => prompt },
      { :disabled => true, :class => 'study_id' }
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
        :class => 'submission_asset_group_id required',
        :disabled => (asset_groups.size == 0)
      }
    )
  end

  def submission_status_message(submission)
    case submission.state
    when 'building' then
      display_user_guide(
        'This submission is still open for editing, further orders can still be added...',
        edit_submission_path(submission)
      ) + button_to("Edit Submission", edit_submission_path(submission), :method => :get, :class => 'button')
    when 'pending' then
      display_user_guide( "Your submission is currently pending.") +
      content_tag(:p, 'It should be processed approximately 10 minutes after you have submitted it, however sometimes this may take longer.')
    when 'processing' then
      display_user_guide("Your submission is currently being processed.  This should take no longer than five minutes.")
    when 'failed' then
      display_user_error("<h2>Your submission has failed:</h2><p> #{h(submission.message)} </p>")
    when 'ready'
      content_tag(:p, 'Your submission has been <strong>processed</strong>.')
    else
      content_tag(:p, 'Your submission is in an unknown state (contact support).')
    end
  end

  def order_sample_names(order)
    order.assets.map(&:aliquots).flatten.map(&:sample).map(&:name).join(', ')
  end

  def request_description(presenter, request_type)
    request_type_name = request_type.name.titleize

    return request_type_name unless request_type.request_class_name =~ /SequencingRequest$/

    content_tag(:em, pluralize(presenter.lanes_of_sequencing, 'Lane') + ' of ') + request_type_name
  end
end
