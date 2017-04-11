# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Request::ChangeDecision
  include ::Validateable

  class ChangeDecisionError < ::StandardError
    attr_reader :object
    def initialize(object)
      @object = object
    end
  end

  InvalidDecision = Class.new(ChangeDecisionError)

  attr_accessor :change_decision_check_box
  attr_accessor :asset_qc_state_check_box

  def checkboxes
    [change_decision_check_box, asset_qc_state_check_box]
  end
  validates_each(:checkboxes) do |record, attribute, list_of_checkbox_values|
    record.errors.add(attribute, 'at least one must be selected') if list_of_checkbox_values.all? { |v| v.blank? or v == '0' }
  end

  attr_accessor :asset_qc_state
  validates_each(:asset_qc_state, unless: :asset_qc_state_absent?) do |record, _attr, value|
    if not record.request.target_asset.has_been_through_qc?
      record.errors.add(:asset, 'has not been through QC')
    elsif value == record.request.target_asset.qc_state
      record.errors.add(:asset_qc_state, 'cannot be same as current state')
    end
  end
  validates_presence_of :asset_qc_state, unless: :asset_qc_state_absent?

  attr_accessor :comment
  validates_presence_of :comment

  attr_accessor :request

  attr_accessor :user
  validates_presence_of(:request)

  def initialize(attributes)
    attributes.each { |k, v| send(:"#{k}=", v) }
  end

  def state_change?
    change_decision_check_box == '1'
  end

  def asset_qc_state_absent?
    asset_qc_state_check_box == '0' || asset_qc_state_check_box.nil?
  end

  def execute!
    raise InvalidDecision, self unless valid?
    perform_decision_change!
  end

private

  def perform_decision_change!
    begin
      ActiveRecord::Base.transaction do
        perform_decision_change_request_state! if state_change?
        perform_decision_change_asset_qc_state! unless asset_qc_state_absent?
      end
    rescue ActiveRecord::RecordInvalid => exception
      reload_objects
      raise InvalidDecision, self
    end
  end

  def reload_objects
    request.reload
    request.target_asset.reload
  end

  def perform_decision_change_request_state!
    previous_state = request.state
    ActiveRecord::Base.transaction do
      # Really this toggle of states isn't ideal, as effectively it means
      # multiple requests in quick succession could toggle the state, which probably
      # wasn't the intended behaviour.
      case
      when request.failed? then request.retrospective_pass!
      when request.passed? then request.retrospective_fail!
      else
        raise InvalidDecision, self
      end
      request.events.create!(message: "Change state from #{previous_state} to  #{state}", created_by: user.login, family: 'update')
      request.comments.create!(description: comment, user_id: user.id)
    end
  end

  def perform_decision_change_asset_qc_state!
    previous_state = request.target_asset.qc_state
    request.target_asset.set_qc_state(asset_qc_state)
    # self.request.asset.events << Event.new({:message => "Change qc_state from #{previous_state} to  #{asset_qc_state}", :created_by => self.user.login, :family => self.asset_qc_state})
    request.target_asset.comments.create!(description: comment, user_id: user.id)
  end
end
