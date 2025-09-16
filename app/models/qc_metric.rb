# frozen_string_literal: true
class QcMetric < ApplicationRecord
  extend QcMetric::QcState

  InvalidValue = Class.new(StandardError)

  QC_DECISION_TRANSITIONS = {
    'passed' => 'manually_passed',
    'manually_passed' => 'manually_passed',
    'failed' => 'manually_failed',
    'manually_failed' => 'manually_failed'
  }.freeze

  PROCEED_TRANSLATION = { true => 'Y', false => 'N' }.freeze

  new_state 'passed'
  new_state 'failed', passed: false
  new_state 'manually_passed', automatic: false
  new_state 'manually_failed', passed: false, automatic: false
  new_state 'unprocessable', passed: false, proceedable: false

  belongs_to :asset, class_name: 'Receptacle'
  belongs_to :qc_report
  has_one :product_criteria, through: :qc_report
  validates :asset, :qc_report, presence: true
  validates :qc_decision, inclusion: { in: QcMetric.valid_states }

  serialize :metrics, coder: YAML

  scope :with_asset_ids, ->(ids) { where(asset_id: ids) }

  scope :for_product,
        ->(product) { joins(qc_report: :product_criteria).where(product_criteria: { product_id: product }) }

  scope :stock_metric,
        -> { joins(qc_report: :product_criteria).where(product_criteria: { stage: ProductCriteria::STAGE_STOCK }) }

  scope :most_recent_first, -> { order(created_at: :desc, id: :desc) }

  before_save :update_aliquot_quality

  # Update the new state as appropriate:
  # - Don't change the state if we already match
  # - If we have an automatic state, update to a manual state
  # - If we already have a manual state, perform some magic to ensure eg.
  #   pass -> manual_fail -> pass  BUT
  #   unprocessable -> manual_fail -> manual_pass
  def manual_qc_decision=(decision)
    return if qc_decision == decision
    return self.qc_decision = decision_to_manual_state(decision) if qc_automatic?
    return self.qc_decision = decision if original_qc_decision == decision

    self.qc_decision = decision_to_manual_state(decision)
  end

  def human_proceed
    PROCEED_TRANSLATION[proceed]
  end

  def human_proceed=(h_proceed)
    return self.proceed = nil if h_proceed.blank?

    self.proceed = proceedable? && human_to_bool(PROCEED_TRANSLATION, h_proceed.upcase)
  end

  # The metric indicates that the sample has been progressed despite poor quality
  # || false ensures nil gets converted to a boolean
  def poor_quality_proceed
    (qc_failed? && proceed) || false
  end

  def qc_passed?
    qc_state_object.passed
  end

  def qc_failed?
    !qc_passed?
  end

  def proceedable?
    qc_state_object.proceedable
  end

  def qc_automatic?
    qc_state_object.automatic
  end

  def original_qc_decision
    qc_report.original_qc_decision(metrics)
  end

  private

  def qc_state_object
    QcMetric.qc_state_object_called(qc_decision)
  end

  def decision_to_manual_state(decision)
    hash = QC_DECISION_TRANSITIONS
    hash[decision].tap { |v| raise(InvalidValue, value_error_message(decision, hash.keys)) if v.nil? }
  end

  def human_to_bool(hash, choice)
    hash.key(choice).tap { |v| raise(InvalidValue, value_error_message(choice, hash.values)) if v.nil? }
  end

  def value_error_message(decision, accepted_list)
    accepted = accepted_list.to_sentence(last_word_connector: ', or ', two_words_connector: ' or ')
    "#{decision} is not an acceptable decision. Should be #{accepted}."
  end

  def update_aliquot_quality
    asset.update_aliquot_quality(qc_failed?)
  end
end
