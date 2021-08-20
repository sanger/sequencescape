# frozen_string_literal: true

# A few helpers used in pipeline workflows
module WorkflowsHelper
  # Returns a link to any available request comments with "None" as a
  # default value.
  def link_to_comments(request)
    link_to_if(request.comments.present?, pluralize(request.comments.size, 'comment'), request_comments_url(request)) do
      'None'
    end
  end

  def tag_index_for(request)
    batch_tag_index[request.asset_id]
  end

  def batch_tag_index
    @tag_hash ||=
      Tag
        .joins(:aliquots)
        .where(aliquots: { receptacle_id: @batch.requests.map(&:asset_id) })
        .pluck(:receptacle_id, :map_id)
        .to_h
        .tap { |th| th.default = '-' }
  end

  def qc_select_box(request, status, html_options = {})
    select_options = %w[pass fail]
    select_tag(
      "#{request.id}[qc_state]",
      options_for_select(select_options, status),
      html_options.merge(class: 'qc_state')
    )
  end

  def gel_qc_select_box(request, status, html_options = {})
    html_options.delete(:generate_blank)
    status = 'OK' if status.blank? || status == 'Pass'
    select_tag(
      "wells[#{request.id}][qc_state]",
      options_for_select(
        {
          'Pass' => 'OK',
          'Fail' => 'Fail',
          'Weak' => 'Weak',
          'No Band' => 'Band Not Visible',
          'Degraded' => 'Degraded'
        },
        status
      ),
      html_options
    )
  end
end
