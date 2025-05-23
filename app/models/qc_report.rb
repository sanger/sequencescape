# frozen_string_literal: true
class QcReport < ApplicationRecord
  # :id => The primary key for internal use only
  # :report_identifier => A unique identifier exposed to customers
  # :state => Tracks report processing and return

  include AASM

  module StateMachine
    module ClassMethods
      def available_states
        QcReport.aasm.states.map { |state| state.name.to_s }
      end
    end

    # rubocop:todo Metrics/MethodLength
    def self.included(base) # rubocop:todo Metrics/AbcSize
      base.class_eval do
        # When adding new states, please make sure you update the config/locals/en.yml file
        # with descriptions.

        # We disable the transactions here as otherwise our entire job gets wrapped in a transaction.
        # This causes problems for very large reports, as it causes objects with after transaction callbacks to
        # be persisted for the entire job. We'd already chunked our transaction into batches, but this transaction
        # was counteracting that.
        aasm column: :state, whiny_persistence: true, use_transactions: false do
          # A report has just been created and is awaiting processing. There is probably a corresponding delayed job
          state :queued, initial: true

          # A report has failed one or more times. Generally this means there is a problem.
          state :requeued

          # The report has been picked up by the delayed job. Entry into this state triggers building.
          state :generating, after_enter: :generate_report

          # The report has been generated and is awaiting customer feedback
          state :awaiting_proceed

          # Customer feedback has been uploaded. This is generally an end state, but a report can be re-uploaded
          # at a later date if necessary.
          state :complete

          # Triggered automatically on after_create. This event is handled via
          # schedule_report, which creates a delayed job. It can be called manually.
          event :generate do
            transitions from: %i[queued requeued], to: :generating
          end

          # Called on report failure. Generally the delayed job will cycle it through a few times
          # but most reports in this state will require manual intervention.
          event :requeue do
            transitions from: :generating, to: :requeued
          end

          # Called automatically when a report is generated
          event :generation_complete do
            transitions from: :generating, to: :awaiting_proceed
          end

          # A QC report might be uploaded multiple times
          event :proceed_decision do
            transitions from: %i[complete awaiting_proceed], to: :complete
          end
        end

        def available?
          awaiting_proceed? or complete?
        end

        extend ClassMethods
      end
    end
    # rubocop:enable Metrics/MethodLength
  end

  module ReportBehaviour
    # Generates the report.
    # Generally speaking this gets triggered automatically, and is handled by the delayed job.
    # Briefly, an after_create event creates a delayed job to call generate! on the report.
    # This transitions the report into 'generating' and triggers this event.
    # On completion the report automatically passes into 'awaiting_proceed' through generation_complete!
    # You can trigger a synchronous report manually by calling #generate!
    # rubocop:todo Metrics/MethodLength
    def generate_report # rubocop:todo Metrics/AbcSize
      study.each_well_for_qc_report_in_batches(
        exclude_existing,
        product_criteria,
        (plate_purposes.empty? ? nil : plate_purposes)
      ) do |assets|
        # If there are some wells of interest, we get them in a list
        connected_wells = Well.hash_stock_with_targets(assets, product_criteria.target_plate_purposes)

        # This transaction is inside the block as otherwise large reports experience issues
        # with high memory usage. In the event that an exception is raised the most
        # recent set of decisions will be rolled back, and the report will be re-queued.
        # The rescue event clears out the remaining metrics, this avoids the risk of duplicate
        # metric on complete reports (Although wont help if, say, the database connection fails)
        ActiveRecord::Base.transaction do
          assets.each do |asset|
            criteria = product_criteria.assess(asset, connected_wells[asset.id])
            QcMetric.create!(
              asset: asset,
              qc_decision: criteria.qc_decision,
              metrics: criteria.metrics,
              qc_report: self
            )
          end
        end
      end
      generation_complete!
    rescue => e
      # If something goes wrong, requeue the report and re-raise the exception
      qc_metrics.clear
      requeue!
      raise e
    end

    # rubocop:enable Metrics/MethodLength
    private :generate_report
  end

  include StateMachine
  include ReportBehaviour

  belongs_to :product_criteria
  has_one :product, through: :product_criteria
  belongs_to :study
  has_many :qc_metrics

  serialize :plate_purposes, type: Array, coder: YAML

  before_validation :generate_report_identifier, if: :identifier_required?

  after_create :schedule_report

  scope :for_report_page, ->(conditions) { order('id desc').where(conditions).joins(:product_criteria) }

  validates :product_criteria, :study, :state, presence: true

  validates :exclude_existing, inclusion: { in: [true, false], message: 'should be true or false.' }

  # Reports are handled asynchronously
  def schedule_report
    Delayed::Job.enqueue QcReportJob.new(id)
  end

  def to_param
    report_identifier
  end

  def product_id
    product.try(:id)
  end

  def original_qc_decision(metrics)
    product_criteria.asses(metrics)
  end

  private

  def identifier_required?
    report_identifier.nil?
  end

  # NOTE: You won't be able to generate two reports for the
  # same product / study abbreviation combo within one second
  # of each other.
  def generate_report_identifier
    return true if study.nil? || product_criteria.nil?

    rid = [study.abbreviation, product_criteria.product.name, DateTime.now.to_fs(:number)].compact
      .join('_')
      .downcase
      .gsub(/[^\w]/, '_')
    self.report_identifier = rid
  end
end
