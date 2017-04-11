# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

module SubmissionsHelper
  # Returns an array (or anything else) as an escaped string for
  # embedding in javascript
  def stringify_array(projects_array)
    projects_array.inspect
  end

  # <label for="submission_order_params_field_info_key">field_info.display_name/label>
  def order_input_label(field_info)
    label('submission[order_params]', field_info.key, field_info.display_name, class: 'control-label col-sm-6')
  end

  # Returns a either a text input or a selection tag based on the 'kind'
  # of the order parameter passed in.
  # field_info is expected to be FieldInfo [sic]
  def order_input_tag(order, field_info)
    content_tag(:div, class: 'col-sm-6') do
      case field_info.kind
      when 'Selection' then order_selection_tag(order, field_info)
      when 'Text'      then order_text_tag(order, field_info)
      when 'Numeric'   then order_number_tag(order, field_info)
      # Fall back to a text field
      else order_text_tag(order, field_info)
      end
    end
  end

  def order_selection_tag(order, field_info)
    select_tag(
      "submission[order_params][#{field_info.key}]",
      options_for_select(
        field_info.selection.map(&:to_s),
        order.request_options.try(:[], field_info.key)
      ),
      class: 'required form-control',
      required: true,
      disabled: (field_info.selection.size == 1)
    )
  end
  private :order_selection_tag

  def order_text_tag(order, field_info)
    text_field_tag(
      "submission[order_params][#{field_info.key}]",
      order.request_options.try(:[], field_info.key) || field_info.default_value,
      class: 'required form-control',
      required: true
    )
  end
  private :order_text_tag

  def order_number_tag(order, field_info)
    number_field_tag(
      "submission[order_params][#{field_info.key}]",
      order.request_options.try(:[], field_info.key) || field_info.default_value,
      class: 'required form-control',
      required: true
    )
  end
  private :order_text_tag

  def studies_select(form, studies)
    prompt = case studies.count
             when 0 then 'You are not managing any Studies at this time'
             else 'Please select a Study for this Submission...'
             end

    form.collection_select(
      :study_id,
      studies, :id, :name,
      { prompt: prompt },
      disabled: true, class: 'study_id form-control'
    )
  end

  def projects_select(form, projects)
    prompt = case projects.count
             when 0 then 'There are no valid projects available'
             else 'Please select a Project for this Submission...'
             end
    # form.text_field :project_name,
    #       :class       => 'submission_project_name form-control form-control',
    #       :placeholder => "enter the first few characters of the financial project name",
    #       :disabled    => true

    form.collection_select(
      :project_name,
      projects, :name, :name,
      { prompt: prompt },
      disabled: true, class: 'submission_project_name form-control'
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
              disabled: (asset_groups.size == 0)
    )
  end

  def submission_status_message(submission)
    case submission.state
    when 'building' then
      display_user_guide(
        'This submission is still open for editing, further orders can still be added...',
        edit_submission_path(submission)
      ) + button_to('Edit Submission', edit_submission_path(submission), method: :get, class: 'button')
    when 'pending' then
      display_user_guide('Your submission is currently pending.') +
        content_tag(:p, 'It should be processed approximately 10 minutes after you have submitted it, however sometimes this may take longer.')
    when 'processing' then
      display_user_guide('Your submission is currently being processed.  This should take no longer than five minutes.')
    when 'failed' then
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

    return request_type_name unless request_type.request_class_name =~ /SequencingRequest$/

    content_tag(:em, pluralize(presenter.lanes_of_sequencing, 'Lane') + ' of ') + request_type_name
  end

  def submission_link(submission, options)
    link_text = content_tag(:strong, submission.name) << ' ' <<
                content_tag(:span, submission.state, class: "batch-state label label-#{bootstrapify_submission_state(submission.state)}")
    link_to(link_text, submission_path(submission), options)
  end
end
