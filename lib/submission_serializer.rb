# frozen_string_literal: true
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
  STRAIGHT_CLONE = %w[name submission_class_name].freeze
  SP_STRAIGHT_CLONE = %i[info_differential asset_input_methods request_options].freeze

  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def self.serialize(st) # rubocop:todo Metrics/CyclomaticComplexity
    attributes = st.attributes
    new_attributes = {}

    STRAIGHT_CLONE.each do |key|
      new_attributes[key.to_sym] = attributes[key].duplicable? ? attributes[key].dup : attributes[key]
    end

    if attributes['product_line_id']
      new_attributes[:product_line] = ProductLine.find(attributes['product_line_id']).name
    end
    if attributes['product_catalogue_id']
      new_attributes[:product_catalogue] = ProductCatalogue.find(attributes['product_catalogue_id']).name
    end
    if attributes['superceded_by_id'] > 0
      new_attributes[:superceded_by] = SubmissionTemplate.find(attributes['superceded_by_id']).name
    end
    new_attributes[:superceded_by_id] = attributes['superceded_by_id']
    new_attributes[:superceded_at] = attributes['superceded_at'].to_s if attributes['superceded_at']

    sp = attributes['submission_parameters'] || {}
    ensp = new_attributes[:submission_parameters] = {}

    SP_STRAIGHT_CLONE.each { |key| ensp[key] = sp[key] if sp[key].present? }

    if ensp[:request_options] && ensp[:request_options][:initial_state]
      new_initial = ensp[:request_options][:initial_state].transform_keys { |k| RequestType.find(k).key }
      ensp[:request_options][:initial_state] = new_initial
    end

    ensp[:request_types] = sp[:request_type_ids_list].flatten.map { |id| RequestType.find(id).key }
    ensp[:order_role] = OrderRole.find(sp[:order_role_id]).role if sp[:order_role_id]

    new_attributes
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def self.construct!(hash) # rubocop:todo Metrics/CyclomaticComplexity
    st = {}

    STRAIGHT_CLONE.each { |key| st[key.to_sym] = hash[key.to_sym] }

    st[:product_line_id] = ProductLine.find_or_create_by(name: hash[:product_line]).id if hash[:product_line]
    if hash[:product_catalogue]
      st[:product_catalogue_id] = ProductCatalogue.find_or_create_by(name: hash[:product_catalogue]).id
    end
    st[:superceded_by_id] = if hash.has_key?(:superceded_by)
      SubmissionTemplate.find_by(name: hash[:superceded_by]).try(:id) || -2
    else
      hash[:superceded_by_id] || -1
    end
    st[:superceded_at] = DateTime.parse(hash[:superceded_at]) if hash.has_key?(:superceded_at)

    sp = st[:submission_parameters] = {}
    ensp = hash[:submission_parameters]

    SP_STRAIGHT_CLONE.each { |key| sp[key] = ensp[key] if ensp[key].present? }

    if sp[:request_options] && sp[:request_options][:initial_state]
      new_initial = sp[:request_options][:initial_state].transform_keys { |k| RequestType.find_by(key: k).id }
      sp[:request_options][:initial_state] = new_initial
    end

    sp[:request_type_ids_list] = ensp[:request_types].map do |rtk|
      [(RequestType.find_by(key: rtk).try(:id) || raise(StandardError, "Could not find #{rtk}"))]
    end
    sp[:order_role_id] = OrderRole.find_or_create_by(role: ensp[:order_role]).id if ensp[:order_role]

    SubmissionTemplate.create!(st)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
end
