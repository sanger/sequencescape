# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'aasm'

class Request < ActiveRecord::Base
  include ModelExtensions::Request
  include Aliquot::DeprecatedBehaviours::Request

  include Api::RequestIO::Extensions

  self.per_page = 500

  include Uuid::Uuidable
  include AASM
  include Commentable
  include StandardNamedScopes
  include Request::Statemachine
  extend Request::Statistics
  include Batch::RequestBehaviour

  extend EventfulRecord
  has_many_events
  has_many_lab_events

  self.inheritance_column = 'sti_type'

  class_attribute :customer_request
  self.customer_request = false

  def self.delegate_validator
    DelegateValidation::AlwaysValidValidator
  end

  scope :for_pipeline, ->(pipeline) {
      joins('LEFT JOIN pipelines_request_types prt ON prt.request_type_id=requests.request_type_id')
        .where(['prt.pipeline_id=?', pipeline.id])
        .readonly(false)
  }

  def validator_for(request_option)
    request_type.request_type_validators.find_by(request_option: request_option.to_s) || raise("#{request_type.name} has no #{request_option} validator!")
  end

  scope :customer_requests, ->() { where(sti_type: [CustomerRequest, *CustomerRequest.descendants].map(&:name)) }

  def customer_request?
    customer_request
  end

   scope :for_pipeline, ->(pipeline) {
      joins('LEFT JOIN pipelines_request_types prt ON prt.request_type_id=requests.request_type_id')
        .where(['prt.pipeline_id=?', pipeline.id])
        .readonly(false)
                        }

  scope :for_pooling_of, ->(plate) {
    submission_ids = plate.all_submission_ids
    add_joins =
      if plate.stock_plate?
        ['INNER JOIN assets AS pw ON requests.asset_id=pw.id']
      else
        [
          'INNER JOIN well_links ON well_links.source_well_id=requests.asset_id',
          'INNER JOIN assets AS pw ON well_links.target_well_id=pw.id AND well_links.type="stock"',
        ]
      end

    select('uuids.external_id AS pool_id, GROUP_CONCAT(DISTINCT pw_location.description ORDER BY pw.map_id ASC SEPARATOR ",") AS pool_into, MIN(requests.id) AS id, MIN(requests.sti_type) AS sti_type, MIN(requests.submission_id) AS submission_id, MIN(requests.request_type_id) AS request_type_id')
      .joins(add_joins + [
        'INNER JOIN maps AS pw_location ON pw.map_id=pw_location.id',
        'INNER JOIN container_associations ON container_associations.content_id=pw.id',
        'INNER JOIN uuids ON uuids.resource_id=requests.submission_id AND uuids.resource_type="Submission"'
      ])
      .group('uuids.external_id')
      .customer_requests
      .where([
        'container_associations.container_id=? AND requests.submission_id IN (?)',
        plate.id, submission_ids
      ])
  }

  scope :for_pre_cap_grouping_of, ->(plate) {
    add_joins =
      if plate.stock_plate?
        ['INNER JOIN assets AS pw ON requests.asset_id=pw.id']
      else
        [
          'INNER JOIN well_links ON well_links.source_well_id=requests.asset_id',
          'INNER JOIN assets AS pw ON well_links.target_well_id=pw.id AND well_links.type="stock"',
        ]
      end

      select('min(uuids.external_id) AS group_id, GROUP_CONCAT(DISTINCT pw_location.description SEPARATOR ",") AS group_into, MIN(requests.id) AS id, MIN(requests.submission_id) AS submission_id, MIN(requests.request_type_id) AS request_type_id')
        .joins(add_joins + [
          'INNER JOIN maps AS pw_location ON pw.map_id = pw_location.id',
          'INNER JOIN container_associations ON container_associations.content_id=pw.id',
          'INNER JOIN pre_capture_pool_pooled_requests ON requests.id=pre_capture_pool_pooled_requests.request_id',
          'INNER JOIN uuids ON uuids.resource_id = pre_capture_pool_pooled_requests.pre_capture_pool_id AND uuids.resource_type="PreCapturePool"'
        ])
        .group('pre_capture_pool_pooled_requests.pre_capture_pool_id')
        .customer_requests
        .where(state: 'pending')
        .where([
          'container_associations.container_id=?',
          plate.id
        ])
  }

  scope :in_order, ->(order) { where(order_id: order) }

  scope :for_event_notification_by_order, ->(order) {
    customer_requests.in_order(order).where(state: 'passed')
  }

  scope :including_samples_from_target, ->() { includes(target_asset: { aliquots: :sample }) }
  scope :including_samples_from_source, ->() { includes(asset: { aliquots: :sample }) }

  scope :for_order_including_submission_based_requests, ->(order) {
    # To obtain the requests for an order and the sequencing requests of its submission (as they are defined
    # as a common element for any order in the submission)
    where(['requests.order_id=? OR (requests.order_id IS NULL AND requests.submission_id=?)', order.id, order.submission.id])
  }

  belongs_to :pipeline
  belongs_to :item

  has_many :failures, as: :failable

  has_many :samples, through: :asset, source: :samples

  belongs_to :request_type, inverse_of: :requests
  delegate :billable?, to: :request_type, allow_nil: true
  belongs_to :workflow, class_name: 'Submission::Workflow'

  belongs_to :user
  belongs_to :request_purpose
  validates_presence_of :request_purpose

  belongs_to :submission, inverse_of: :requests
  belongs_to :submission_pool, foreign_key: :submission_id

  belongs_to :order, inverse_of: :requests

  # has_many :submission_siblings, ->(request) { where(:request_type_id => request.request_type_id) }, :through => :submission, :source => :requests, :class_name => 'Request'
  has_many :qc_metric_requests
  has_many :qc_metrics, through: :qc_metric_requests
  has_many :request_events, ->() { order(:current_from) }, inverse_of: :request

  scope :with_request_type_id, ->(id) { where(request_type_id: id) }
  scope :for_pacbio_sample_sheet, -> { includes([{ target_asset: :map }, :request_metadata]) }
  scope :for_billing, -> { includes([:initial_project, :request_type, { target_asset: :aliquots }]) }

  # project is read only so we can set it everywhere
  # but it will be only used in specific and controlled place
  belongs_to :initial_project, class_name: 'Project'

  def current_request_event
    request_events.current.last
  end

  def project_id=(project_id)
    raise RuntimeError, 'Initial project already set' if initial_project_id
    self.initial_project_id = project_id
  end

  def submission_plate_count
    submission.requests
              .where(request_type_id: request_type_id)
              .joins('LEFT JOIN container_associations AS spca ON spca.content_id = requests.asset_id')
              .count('DISTINCT(spca.container_id)')
  end

  def update_responsibilities!
    # Do nothing
  end

  def project=(project)
    return unless project
    self.project_id = project.id
  end

  # same as project with study
  belongs_to :initial_study, class_name: 'Study'

  def study_id=(study_id)
    raise RuntimeError, 'Initial study already set' if initial_study_id
    self.initial_study_id = study_id
  end

  def study=(study)
    return unless study
    self.study_id = study.id
  end

  def associated_studies
    return [initial_study] if initial_study.present?
    return asset.studies.uniq if asset.present?
    return submission.studies if submission.present?
    []
  end

 scope :between, ->(source, target) { where(asset_id: source.id, target_asset_id: target.id) }
 scope :into_by_id, ->(target_ids) { where(target_asset_id: target_ids) }

 scope :request_type, ->(request_type) {
    where(request_type_id: request_type)
                      }

  scope :where_is_a?,     ->(clazz) { where(sti_type: [clazz, *clazz.descendants].map(&:name)) }
  scope :where_is_not_a?, ->(clazz) { where(['sti_type NOT IN (?)', [clazz, *clazz.descendants].map(&:name)]) }
  scope :where_has_a_submission, -> { where('submission_id IS NOT NULL') }

  scope :full_inbox, -> { where(state: ['pending', 'hold']) }

  scope :with_asset,  -> { where('asset_id is not null') }
  scope :with_target, -> { where('target_asset_id is not null and (target_asset_id <> asset_id)') }
  scope :join_asset,  -> { joins(:asset) }
  scope :with_asset_location, -> { includes(asset: :map) }

  scope :siblings_of, ->(request) { where(asset_id: request.asset_id).where.not(id: request.id) }

  # Asset are Locatable (or at least some of them)
  belongs_to :location_association, primary_key: :locatable_id, foreign_key: :asset_id
  scope :located, ->(location_id) { joins(:location_association).where(['location_associations.location_id = ?', location_id]).readonly(false) }

  # Use container location
  scope :holder_located, ->(location_id) {
    joins(['INNER JOIN container_associations hl ON hl.content_id = asset_id', 'INNER JOIN location_associations ON location_associations.locatable_id = hl.container_id'])
      .where(['location_associations.location_id = ?', location_id])
      .readonly(false)
  }

  scope :holder_not_control, -> {
    joins(['INNER JOIN container_associations hncca ON hncca.content_id = asset_id', 'INNER JOIN assets AS hncc ON hncc.id = hncca.container_id'])
      .where(['hncc.sti_type != ?', 'ControlPlate'])
      .readonly(false)
  }
  scope :without_asset, -> { where('asset_id is null') }
  scope :without_target, -> { where('target_asset_id is null') }
  scope :excluding_states, ->(states) {
    where.not(state: states)
  }
  scope :ordered, -> { order('id ASC') }
  scope :full_inbox, -> { where(state: ['pending', 'hold']) }
  scope :hold, -> { where(state: 'hold') }

  # Note: These scopes use preload due to a limitation in the way rails handles custom selects with eager loading
  # https://github.com/rails/rails/issues/15185
  scope :loaded_for_inbox_display, -> { preload([{ submission: { orders: :study }, asset: [:scanned_into_lab_event, :studies] }]) }
  scope :loaded_for_grouped_inbox_display, -> { preload([{ submission: :orders }, :asset, :target_asset, :request_type]) }

  scope :ordered_for_ungrouped_inbox, -> { order(id: :desc) }
  scope :ordered_for_submission_grouped_inbox, -> { order(submission_id: :desc, id: :asc) }

  scope :group_conditions, ->(conditions, variables) {
    where([conditions.join(' OR '), *variables])
  }

  def self.group_requests(options = {})
    target = options[:by_target] ? 'target_asset_id' : 'asset_id'
    groupings = options.delete(:group) || {}

    select('requests.*, tca.container_id AS container_id, tca.content_id AS content_id')
      .joins("INNER JOIN container_associations tca ON tca.content_id=#{target}")
      .readonly(false)
      .preload(:request_metadata)
      .group(groupings)
  end

  scope :for_submission_id, ->(id) { where(submission_id: id) }
  scope :for_asset_id, ->(id) { where(asset_id: id) }
  scope :for_study_ids, ->(ids) {
       joins('INNER JOIN aliquots AS al ON requests.asset_id = al.receptacle_id')
         .where(['al.study_id IN (?)', ids]).uniq
                        }

  scope :for_study_id, ->(id) { for_study_ids(id) }

  # Because of our group we need to explicitly declare what we are selecting for 5.7
  # We add :request_type_id to the group by as this allows us to select it without an aggregate operation
  # Now, in practice it hardly matters, as there should be only one request_type_id anyway
  # However, in the event this changes, an aggregate would hide this, so we should probably ensure that
  # its explicit.
  # We select MIN submission_id, this isn't ideal, but struggling to think of an alternative without
  # complete restructuring.
  # Yuck. We also need to select asset_id and target asset_id explicity in Rails 4.
  # Need to completely re-think this.
  scope :for_group_by, ->(attributes) {
    # SELECT and GROUP BY do NOT scrub their input. While there shouldn't be any user provided input
    # comming in here, lets be cautious!
    scrubbed_atts = attributes.map { |k, v| "#{k.to_s.gsub(/[^\w\.]/, '')}.#{v.to_s.gsub(/[^\w\.]/, '')}" }
    scrubbed_atts << 'requests.request_type_id'

    group(scrubbed_atts)
      .select([
        'MIN(requests.id) AS id',
        'MIN(requests.submission_id) AS submission_id',
        'MAX(requests.priority) AS max_priority',
        'hl.container_id AS container_id',
        'count(DISTINCT requests.id) AS request_count',
        'MIN(requests.asset_id) AS asset_id',
        'MIN(requests.target_asset_id) AS target_asset_id'
      ])
      .select(scrubbed_atts)
  }

  def self.for_study(study)
    Request.for_study_id(study.id)
  end

  scope :for_initial_study_id, ->(id) { where(initial_study_id: id) }

  delegate :study, :study_id, to: :asset, allow_nil: true

  scope :for_workflow, ->(workflow) { joins(:workflow).where(workflow: { key: workflow }) }
  scope :for_request_types, ->(types) { joins(:request_type).where(request_types: { key: types }) }

  scope :for_search_query, ->(query, _with_includes) {
     where(['id=?', query])
                           }

   scope :find_all_target_asset, ->(target_asset_id) {
     where(['target_asset_id = ?', target_asset_id.to_s])
   }
   scope :for_studies, ->(*studies) {
     where(initial_study_id: studies)
   }

  scope :with_assets_for_starting_requests, -> { includes([:request_metadata, { asset: :aliquots, target_asset: :aliquots }]) }
  scope :not_failed, -> { where(['state != ?', 'failed']) }

  # TODO: There is probably a MUCH better way of getting this information. This is just a rewrite of the old approach
  def self.get_target_plate_ids(request_ids)
    ContainerAssociation.joins('INNER JOIN requests ON content_id = target_asset_id')
                        .where(['requests.id IN  (?)', request_ids]).uniq.pluck(:container_id)
  end

  # The options that are required for creation.  In other words, the truly required options that must
  # be filled in and cannot be changed if the asset we're creating is used downstream.  For example,
  # a library tube definitely has to have fragment_size_required_from, fragment_size_required_to and
  # library_type and these cannot be changed once the library has been made.
  #
  #--
  # Side note: really this information should be stored on the asset itself, which suggests there is
  # a discrepancy in our model somewhere.
  #++
  def request_options_for_creation
    {}
  end

  def get_value(request_information_type)
    return '' unless request_metadata.respond_to?(request_information_type.key.to_sym)
    value = request_metadata.send(request_information_type.key.to_sym)
    return value.to_s if value.blank? or request_information_type.data_type != 'Date'
    value.to_date.strftime('%d %B %Y')
  end

  def value_for(name, batch = nil)
    rit = RequestInformationType.find_by(name: name)
    rit_value = get_value(rit) if rit.present?
    return rit_value if rit_value.present?

    list = (batch.present? ? lab_events_for_batch(batch) : lab_events)
    list.each { |event| desc = event.descriptor_value_for(name) and return desc }
    ''
  end

  def has_passed(batch, task)
    lab_events_for_batch(batch).any? { |event| event.description == task.name }
  end

  def lab_events_for_batch(batch)
    lab_events.where(batch_id: batch.id)
  end

  def event_with_key_value(k, v = nil)
    v.nil? ? false : lab_events.with_descriptor(k, v).first
  end

  # This is used for the default next or previous request check.  It means that if the caller does not specify a
  # block then we can use this one in its place.
  PERMISSABLE_NEXT_REQUESTS = ->(request) { request.pending? or request.blocked? }

  def next_requests(pipeline, &block)
    # TODO: remove pipeline parameters
    # we filter according to the next pipeline
    next_pipeline = pipeline.next_pipeline
    # return [] if next_pipeline.nil?

    block ||= PERMISSABLE_NEXT_REQUESTS

    eligible_requests = if target_asset.present?
                          target_asset.requests
                        else
                          return [] if submission.nil?
                          submission.next_requests(self)
                        end

    eligible_requests.select do |r|
      (next_pipeline.nil? or
        next_pipeline.request_types_including_controls.include?(r.request_type)
      ) and block.call(r)
    end
  end

  def target_tube
    target_asset if target_asset.is_a?(Tube)
  end

  def previous_failed_requests
    asset.requests.select { |previous_failed_request| (previous_failed_request.failed? or previous_failed_request.blocked?) }
  end

  def add_comment(comment, user)
    comments.create(description: comment, user: user)
  end

  def self.number_expected_for_submission_id_and_request_type_id(submission_id, request_type_id)
    Request.where(submission_id: submission_id, request_type_id: request_type_id)
  end

  def return_pending_to_inbox!
    raise StandardError, "Can only return pending requests, request is #{state}" unless pending?
    remove_unused_assets
  end

  def remove_unused_assets
    ActiveRecord::Base.transaction do
      return if target_asset.nil?
      target_asset.ancestors.clear
      target_asset.destroy
      save!
    end
  end

  def format_qc_information
    return [] if lab_events.empty?

    events.map do |event|
      next if event.family.nil? or not ['pass', 'fail'].include?(event.family.downcase)

      message = event.message || '(No message was specified)'
      { 'event_id' => event.id, 'status' => event.family.downcase, 'message' => message, 'created_at' => event.created_at }
    end.compact
  end

  def copy
    RequestFactory.copy_request(self)
  end

  def cancelable?
    batch_request.nil? && (pending? || blocked?)
  end

  def update_priority
    priority = (self.priority + 1) % 4
    submission.update_attributes!(priority: priority)
  end

  def priority
    submission.try(:priority) || 0
  end

  def request_type_updatable?(_new_request_type)
    pending?
  end

  def customer_accepts_responsibility!
    # Do nothing
  end

  extend ::Metadata
  has_metadata do
  end

  # NOTE: With properties Request#name would have been silently sent through to the property.  With metadata
  # we now need to be explicit in how we want it delegated.
  delegate :name, to: :request_metadata

  # Adds any pool information to the structure so that it can be reported to client applications
  def update_pool_information(pool_information)
    # Does not need anything here
  end

  # def submission_siblings
  #   submission.requests.with_request_type_id(request_type_id)
  # end

  # The date at which the submission was made. In most cases this will be similar to the request's created_at
  # timestamp. We go via submission to ensure that copied requests bear the original timestamp.
  def submitted_at
    # Hopefully we shouldn't get any requests that don't have a submission. But validation is turned off, so
    # we should assume it it possible.
    return '' if submission.nil?
    submission.created_at.strftime('%Y-%m-%d')
  end

  def role
    order.try(:role)
  end

  def self.accessioning_required?
    false
  end

  def ready?
    true
  end

  def target_purpose
    nil
  end

  def library_creation?
    false
  end

  def manifest_processed!; end
end

require_dependency 'system_request'
