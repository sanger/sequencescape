# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012 Genome Research Ltd.
module SubmissionTemplateMaker
  def make_new_templates!(product_line, old_template)
    ActiveRecord::Base.transaction do
      submission_parameters = old_template.submission_parameters.dup

      submission_parameters[:request_type_ids_list] = new_request_types(
        product_line,
        submission_parameters[:request_type_ids_list]
      )

      SubmissionTemplate.create!(
        {
          name: "#{product_line.name} - #{old_template.name}",
          submission_parameters: submission_parameters,
          product_line_id: product_line.id,
          visible: true
        }.reverse_merge(old_template.attributes).except!('created_at', 'updated_at')
      )

      old_template.update_attributes(visible: false)
    end
  end

  def new_request_type(product_line, old_request_type_id_arr)
    # Remember to pull the id out of the wrapping array...
    old_request_type = RequestType.find(old_request_type_id_arr.first)

    new_key = "#{product_line.name.underscore}_#{old_request_type.key}"

    RequestType.find_by(key: new_key) or
      raise "New RequestType '#{new_key}' not found"
  end

  def new_request_types(product_line, old_request_types_list)
    old_request_types_list.map do |old_rtype|
      [new_request_type(product_line, old_rtype).id]
    end
  end
end
