# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

module LabInterface::WorkflowsHelper
  # Returns descriptor from params, if it's not there try the @study.
  # If @study's not set or it doesn't hold the descriptor, return a
  # blank string...
  def descriptor_value(descriptor)
    # Refactored to remove reliance on @values
    params[:values].try(:[], descriptor.name) or
      @study.try(:descriptor_value, descriptor.name) or ''
  end

  # Returns a link to any available request comments with "None" as a
  # default value.
  def link_to_comments(request)
     link_to_if(
       request.comments.present?,
       pluralize(request.comments.size, 'comment'),
       request_comments_url(request)
     ) { 'None' }
  end

  def shorten(string)
    truncate string, 10, '...'
  end

  def not_so_shorten(string)
    truncate string, 15, '...'
  end

  def tag_index_for(request)
    batch_tag_index[request.asset_id]
  end

  def batch_tag_index
    @tag_hash ||= Hash[
      Tag.joins(:aliquots)
        .where(aliquots: { receptacle_id: @batch.requests.map(&:asset_id).uniq })
        .pluck(:receptacle_id, :map_id)].tap { |th| th.default = '-' }
  end

  def qc_select_box(request, status, html_options = {})
    select_options = ['pass', 'fail']
    select_options.unshift('') if html_options.delete(:generate_blank)
    select_tag("#{request.id}[qc_state]", options_for_select(select_options, status), html_options.merge(class: 'qc_state'))
  end

  def gel_qc_select_box(request, status, html_options = {})
    blank = html_options.delete(:generate_blank) ? '<option></option>' : ''
    if status.blank? || status == 'Pass'
      status = 'OK'
    end
    select_tag("wells[#{request.id}][qc_state]", options_for_select({ 'Pass' => 'OK', 'Fail' => 'Fail', 'Weak' => 'Weak', 'No Band' => 'Band Not Visible', 'Degraded' => 'Degraded' }, status), html_options)
  end
end
