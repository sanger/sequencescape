# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

# It associates a name to a pre-filled submission (subclass) and a serialized set of attributes
# We could have use a Prototype Factory , and so just associate a name to existing submission
# but that doesn't work because the submission prototype doesn't pass the validation stage.
# Anyway that's basically a prototype factory
class SubmissionTemplate < ActiveRecord::Base
  include Uuid::Uuidable

  validates_presence_of :name
  validates_presence_of :submission_class_name

  serialize :submission_parameters

  has_many :orders
  belongs_to :product_line

  has_many   :supercedes,    class_name: 'SubmissionTemplate', foreign_key: :superceded_by_id
  belongs_to :superceded_by, class_name: 'SubmissionTemplate', foreign_key: :superceded_by_id

  belongs_to :product_catalogue, inverse_of: :submission_templates
  delegate :product_for, to: :product_catalogue
  validates_presence_of :product_catalogue

  LATEST_VERSION = -1
  SUPERCEDED_BY_UNKNOWN_TEMPLATE = -2

  scope :hidden,               -> { order('product_line_id ASC').where(['superceded_by_id != ?', LATEST_VERSION]) }
  scope :visible,              -> { order('product_line_id ASC').where(superceded_by_id: LATEST_VERSION) }
  scope :include_product_line, -> { includes(:product_line) }

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
        update_attributes!(superceded_by_id: cloned.id, superceded_at: Time.now)
        cloned.update_attributes!(name: name)
      end
    end
  end

  def create_and_build_submission!(attributes)
    Submission.build!(attributes.merge(template: self))
  end

  def create_order!(attributes)
    new_order(attributes).tap do |order|
      yield(order) if block_given?
      order.save!
    end
  end

  def create_with_submission!(attributes)
    create_order!(attributes) do |order|
      order.create_submission(user_id: order.user_id)
    end
  end

  # create a new submission of the good subclass and with pre-set attributes
  def new_order(params = {})
    duped_params = safely_duplicate(params)
    # NOTE: Stringifying request_option keys here is NOT a good idea as it affects multipliers
    attributes = submission_attributes.with_indifferent_access.deep_merge(duped_params)
    infos      = SubmissionTemplate.unserialize(attributes.delete(:input_field_infos))

    submission_class.new(attributes).tap do |order|
      order.template_name = name
      order.product = product_for(attributes)
      order.set_input_field_infos(infos) unless infos.nil?
    end
  end

  # TODO[xxx]: This is a hack just so I can move forward but the request_types stuff should come directly
  def submission_attributes
    return {} if submission_parameters.nil?

    submission_attributes = Marshal.load(Marshal.dump(submission_parameters)) # Deep clone
    submission_attributes[:request_types] = submission_attributes[:request_type_ids_list].flatten
    submission_attributes
  end
  private :submission_attributes

  # Takes in the parameters passed for the order and safely duplicates it so that it can be modified
  # without affecting the caller version.
  #
  # NOTE: You cannot use Marshal.load(Marshal.dump(params)) here because it causes all kinds of problems with
  # the ActiveRecord::Base derived classes when params contains their instances.  It'll appear as insecure
  # method errors somewhere else in the code.
  def safely_duplicate(params)
    params.each_with_object({}) do |(k, v), cloned|
      cloned[k] = if v.is_a?(ActiveRecord::Base)
                    v
                  elsif v.is_a?(Array) and v.first.is_a?(ActiveRecord::Base)
                    v.dup                           # Duplicate the array, but not the contents
                  elsif v.is_a?(Array) or v.is_a?(Hash)
                    Marshal.load(Marshal.dump(v))   # Make safe copies of arrays and hashes
                  else
                    v
                  end
    end
  end
  private :safely_duplicate

  # create a new template from a submission
  def self.new_from_submission(name, submission)
    submission_template = new(name: name)
    submission_template.update_from_submission(submission)
    submission_template
  end

  def update_from_submission(submission)
    self.submission_class_name = submission.class.name
    self.submission_parameters = submission.template_parameters
  end

  def submission_class
    klass = submission_class_name.constantize
    # TODO[mb14] Hack. This is to avoid to have to rename it in database or seen
    # The hack is not needed for subclasses as they inherits from Order
    klass == Submission ? Order : klass
  end

  private

  def self.unserialize(object)
    if object.respond_to? :map
      object.map { |o| unserialize(o) }
    else
      object
    end
  end
end

# SubmissionTemplate is really OrderTemplate, and the only place that actually cares is the API, so alias
OrderTemplate = SubmissionTemplate
