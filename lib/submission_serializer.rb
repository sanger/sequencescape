# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

# Provides a means of serializing and serializing submission templates.
# Example serialization:
# {
#   :name=>"Template Name",
#   :submission_class_name=>"LinearSubmission",
#   :superceded_at=>nil,
#   :product_line=>"Product Line Name",
#   :product_catalogue=>"Product Catalogue Name",
#   :submission_parameters=>{
#     :request_types=>["library_creation", "sequencing"],
#     :workflow=>"short_read_sequencing",
#     :order_role=>"ILC"
#   }
# }

module SubmissionSerializer
  STRAIGHT_CLONE = ['name', 'submission_class_name']
  SP_STRAIGHT_CLONE = [:info_differential, :asset_input_methods, :request_options]

  def self.serialize(st)
    attributes = st.attributes
    new_attributes = {}

   STRAIGHT_CLONE.each do |key|
     new_attributes[key.to_sym] = attributes[key].duplicable? ? attributes[key].dup : attributes[key]
   end

   new_attributes[:product_line] = ProductLine.find(attributes['product_line_id']).name if attributes['product_line_id']
   new_attributes[:product_catalogue] = ProductCatalogue.find(attributes['product_catalogue_id']).name if attributes['product_catalogue_id']
   new_attributes[:superceded_by] = SubmissionTemplate.find(attributes['superceded_by_id']).name if attributes['superceded_by_id'] > 0
   new_attributes[:superceded_by_id] = attributes['superceded_by_id']
   new_attributes[:superceded_at] = attributes['superceded_at'].to_s if attributes['superceded_at']

   sp = attributes['submission_parameters'] || {}
   ensp = new_attributes[:submission_parameters] = {}

   SP_STRAIGHT_CLONE.each do |key|
     ensp[key] = sp[key] if sp[key].present?
   end

   if ensp[:request_options] && ensp[:request_options][:initial_state]
     new_initial = Hash[ensp[:request_options][:initial_state].map { |k, v| [RequestType.find(k).key, v] }]
     ensp[:request_options][:initial_state] = new_initial
   end

   ensp[:request_types] = sp[:request_type_ids_list].flatten.map { |id| RequestType.find(id).key }
   ensp[:workflow] = Submission::Workflow.find(sp[:workflow_id]).key if sp[:workflow_id]
   ensp[:order_role] = Order::OrderRole.find(sp[:order_role_id]).role if sp[:order_role_id]

   new_attributes
  end

  def self.construct!(hash)
    st = {}

    STRAIGHT_CLONE.each do |key|
     st[key.to_sym] = hash[key.to_sym]
    end

    st[:product_line_id] = ProductLine.find_or_create_by(name: hash[:product_line]).id if hash[:product_line]
    st[:product_catalogue_id] = ProductCatalogue.find_or_create_by(name: hash[:product_catalogue]).id if hash[:product_catalogue]
    st[:superceded_by_id] = hash.has_key?(:superceded_by) ? SubmissionTemplate.find_by(name: hash[:superceded_by]).try(:id) || -2 : hash[:superceded_by_id] || -1
    st[:superceded_at] =  DateTime.parse(hash[:superceded_at]) if hash.has_key?(:superceded_at)

    sp = st[:submission_parameters] = {}
    ensp = hash[:submission_parameters]

    SP_STRAIGHT_CLONE.each do |key|
     sp[key] = ensp[key] if ensp[key].present?
    end

    if sp[:request_options] && sp[:request_options][:initial_state]
     new_initial = Hash[sp[:request_options][:initial_state].map { |k, v| [RequestType.find_by(key: k).id, v] }]
     sp[:request_options][:initial_state] = new_initial
    end

    sp[:request_type_ids_list] = ensp[:request_types].map { |rtk| [RequestType.find_by!(key: rtk).id] }
    sp[:workflow_id] = Submission::Workflow.find_by!(key: ensp[:workflow]).id if ensp[:workflow]
    sp[:order_role_id] = Order::OrderRole.find_or_create_by(role: ensp[:order_role]).id if ensp[:order_role]

    SubmissionTemplate.create!(st)
  end
end
