# frozen_string_literal: true
# It associates a name to a pre-filled submission (subclass) and a serialized set of attributes
# We could have use a Prototype Factory , and so just associate a name to existing submission
# but that doesn't work because the submission prototype doesn't pass the validation stage.
# Anyway that's basically a prototype factory
class SubmissionTemplate < ApplicationRecord
  include Uuid::Uuidable

  validates :name, presence: true
  validates :submission_class_name, presence: true

  serialize :submission_parameters, coder: YAML

  has_many :orders
  belongs_to :product_line

  has_many :supercedes, class_name: 'SubmissionTemplate', foreign_key: :superceded_by_id
  belongs_to :superceded_by, class_name: 'SubmissionTemplate'

  belongs_to :product_catalogue, inverse_of: :submission_templates
  delegate :product_for, to: :product_catalogue
  validates :product_catalogue, presence: true

  has_many :products, through: :product_catalogue

  LATEST_VERSION = -1
  SUPERCEDED_BY_UNKNOWN_TEMPLATE = -2

  scope :hidden, -> { order(product_line_id: :asc).where.not(superceded_by_id: LATEST_VERSION) }
  scope :visible, -> { order(product_line_id: :asc).where(superceded_by_id: LATEST_VERSION) }
  scope :include_product_line, -> { includes(:product_line) }

  def self.grouped_by_product_lines
    visible.include_product_line.group_by { |t| t.product_line.try(:name) || 'General' }
  end

  def visible
    superceded_by_id == LATEST_VERSION
  end

  def superceded_by_unknown!
    self.superceded_by_id = SUPERCEDED_BY_UNKNOWN_TEMPLATE
  end

  def supercede
    ActiveRecord::Base.transaction do
      dup.tap do |cloned|
        yield(cloned) if block_given?
        name, cloned.name = cloned.name, "Superceding #{cloned.name}"
        cloned.save!
        update!(superceded_by_id: cloned.id, superceded_at: Time.zone.now)
        cloned.update!(name:)
      end
    end
  end

  def create_order!(attributes)
    new_order(attributes).tap do |order|
      yield(order) if block_given?
      order.save!
    end
  end

  def create_with_submission!(attributes = {})
    create_order!(attributes) { |order| order.create_submission(user_id: order.user_id) }
  end

  # create a new submission of the good subclass and with pre-set attributes
  def new_order(params = {})
    duped_params = safely_duplicate(params)

    # NOTE: Stringifying request_option keys here is NOT a good idea as it affects multipliers
    attributes = submission_attributes.with_indifferent_access.deep_merge(duped_params)

    submission_class
      .new(attributes)
      .tap do |order|
        order.template_name = name
        order.product = product_for(attributes)
      end
  end

  def submission_class
    submission_class_name.constantize
  end

  def input_field_infos
    FieldInfo.for_request_types(request_types)
  end

  def sequencing?
    request_types.any?(&:sequencing)
  end

  def input_asset_type
    sorted_request_types.first.asset_type
  end

  def input_plate_purposes
    sorted_request_types.first.acceptable_purposes
  end

  private

  # Retrieves the request types that are associated with this submission template,
  # from the ids that are specified in the submission_parameters field.
  def request_types
    @request_types ||= RequestType.where(id: request_type_ids)
  end

  # Returns the request types in the order that they are specified in the submission_parameters field.
  def sorted_request_types
    request_types.sort_by { |rt| request_type_ids.index(rt.id) }
  end

  def request_type_ids
    submission_parameters[:request_type_ids_list].flatten
  end

  # TODO[xxx]: This is a hack just so I can move forward but the request_types stuff should come directly
  def submission_attributes
    return {} if submission_parameters.nil?

    submission_attributes = Marshal.load(Marshal.dump(submission_parameters)) # Deep clone
    submission_attributes[:request_types] = request_type_ids
    submission_attributes
  end

  # Takes in the parameters passed for the order and safely duplicates it so that it can be modified
  # without affecting the caller version.
  #
  # NOTE: You cannot use Marshal.load(Marshal.dump(params)) here because it causes all kinds of problems with
  # the ActiveRecord::Base derived classes when params contains their instances.  It'll appear as insecure
  # method errors somewhere else in the code.
  def safely_duplicate(params) # rubocop:todo Metrics/MethodLength
    params.transform_values do |v|
      if v.is_a?(ActiveRecord::Base)
        v
      elsif v.is_a?(Array) && v.first.is_a?(ActiveRecord::Base)
        v.dup # Duplicate the array, but not the contents
      elsif v.is_a?(Array) || v.is_a?(Hash)
        Marshal.load(Marshal.dump(v)) # Make safe copies of arrays and hashes
      else
        v
      end
    end
  end
end
