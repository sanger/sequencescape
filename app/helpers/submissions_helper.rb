# frozen_string_literal: true

# Helper methods for presenting submission related information
module SubmissionsHelper
  # <label for="submission_order_params_field_info_key">field_info.display_name/label>
  def order_input_label(field_info)
    label('submission[order_params]', field_info.key, field_info.display_name, class: 'form-label')
  end

  # Returns a either a text input or a selection tag based on the 'kind'
  # of the order parameter passed in.
  # field_info is expected to be FieldInfo [sic]
  def order_input_tag(order, field_info)
    request_options = order&.request_options || {}
    field_input_tag(
      field_info,
      values: request_options,
      name_format: 'submission[order_params][%s]'
    )
  end

  def field_input_tag(field_info, values: {}, name_format: '%s', enforce_required: true)
    case field_info.kind
    when 'Selection' then field_selection_tag(values, field_info, name_format, enforce_required)
    when 'Text'      then field_text_tag(values, field_info, name_format, enforce_required)
    when 'Numeric'   then field_number_tag(values, field_info, name_format, enforce_required)
    # Fall back to a text field
    else field_text_tag(values, field_info, name_format, enforce_required)
    end
  end

  def studies_select(form, studies)
    prompt = case studies.count
             when 0 then 'You are not managing any Studies at this time'
             else 'Please select a Study for this Submission...'
             end

    form.collection_select(
      :study_id,
      studies, :id, :name,
      { prompt: prompt },
      disabled: true, class: 'study_id custom-select'
    )
  end

  def projects_select(form, projects)
    prompt = case projects.count
             when 0 then 'There are no valid projects available'
             else 'Please select a Project for this Submission...'
             end
    form.collection_select(
      :project_name,
      projects, :name, :name,
      { prompt: prompt },
      disabled: true, class: 'submission_project_name custom-select'
    )
  end

  def asset_group_select(asset_groups)
    prompt = case asset_groups.size
             when 0 then 'There are no Asset Groups associcated with this Study'
             else 'Please select an asset group for this order.'
             end

    collection_select(
      :submission,
      :asset_group_id,
      asset_groups, :id, :name,
      { prompt: prompt },
      class: 'submission_asset_group_id required form-control',
      disabled: asset_groups.empty?
    )
  end

  def submission_status_message(submission)
    case submission.state
    when 'building'
      display_user_guide(
        'This submission is still open for editing, further orders can still be added...',
        edit_submission_path(submission)
      ) + button_to('Edit Submission', edit_submission_path(submission), method: :get, class: 'button')
    when 'pending'
      display_user_guide('Your submission is currently pending.') +
        tag.p('It should be processed approximately 10 minutes after you have submitted it, however sometimes this may take longer.')
    when 'processing'
      display_user_guide('Your submission is currently being processed.  This should take no longer than five minutes.')
    when 'failed'
      display_user_error(raw("<h3>Your submission has failed:</h3><p> #{h((submission.message || 'No failure reason recorded').lines.first)} </p>"))
    when 'ready'
      alert(:success) { raw('Your submission has been <strong>processed</strong>.') }
    when 'cancelled'
      alert(:info) { raw('Your submission has been <strong>cancelled</strong>.') }
    else
      alert(:danger) { 'Your submission is in an unknown state (contact support).' }
    end
  end

  def order_sample_names(order)
    order.assets.map(&:aliquots).flatten.map(&:sample).map(&:name).join(', ')
  end

  def request_description(presenter, request_type)
    request_type_name = request_type.name.titleize

    return request_type_name unless request_type.request_class_name.match?(/SequencingRequest$/)

    tag.em(pluralize(presenter.lanes_of_sequencing, 'Lane') + ' of ') + request_type_name
  end

  def submission_link(submission, options)
    link_text = tag.strong(submission.name) << ' ' <<
                badge(submission.state, type: 'submission-state')
    link_to(link_text, submission_path(submission), options)
  end

  private

  def field_selection_tag(request_options, field_info, name_format, enforce_required)
    select_tag(
      name_format % field_info.key,
      options_for_select(
        field_info.selection.map(&:to_s),
        request_options[field_info.key]
      ),
      class: 'custom-select',
      required: enforce_required && field_info.required,
      read_only: field_info.selection.size == 1
    )
  end

  def field_text_tag(request_options, field_info, name_format, enforce_required)
    text_field_tag(
      name_format % field_info.key,
      request_options[field_info.key] || field_info.default_value,
      class: 'required form-control',
      required: enforce_required && field_info.required
    )
  end

  def field_number_tag(request_options, field_info, name_format, enforce_required)
    number_field_tag(
      name_format % field_info.key,
      request_options[field_info.key] || field_info.default_value,
      class: 'required form-control',
      required: enforce_required && field_info.required
    )
  end
end
