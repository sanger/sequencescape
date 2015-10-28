#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class QcReport < ActiveRecord::Base

  # :id => The primary key for internal use only
  # :report_identifier => A unique identifier exposed to customers
  # :state => Tracks report processing and return

  include AASM

  module StateMachine

    module ClassMethods
      def available_states
        QcReport.aasm_states.map {|state| state.name.to_s }
      end
    end

    def self.included(base)
      base.class_eval do

        # When adding new states, please make sure you update the config/locals/en.yml file
        # with decriptions.

        aasm_column :state

        aasm_state :queued
        aasm_state :generating, :after_enter => :generate_report
        aasm_state :awaiting_proceed
        aasm_state :complete

        aasm_event :generate do
          transitions :from => :queued, :to => :generating
        end

        aasm_event :generation_complete do
          transitions :from => :generating, :to => :awaiting_proceed
        end

        # A QC report might be uploaded multiple times
        aasm_event :proceed_decision do
          transitions :from => [:complete,:awaiting_proceed], :to => :complete
        end

        aasm_initial_state :queued

        def available?
          awaiting_proceed? or complete?
        end

        extend ClassMethods

      end

    end
  end

  module ReportBehaviour
    def generate_report
      ActiveRecord::Base.transaction do
        study.each_well_for_qc_report(exclude_existing,product_criteria) do |asset|
          criteria = product_criteria.assess(asset)
          qc_metrics.build(:asset=>asset,:qc_decision=>criteria.passed?,:metrics=>criteria.metrics)
        end
        save!
        generation_complete!
      end
    end
  end

  include StateMachine
  include ReportBehaviour

  belongs_to :product_criteria
  has_one :product, :through => :product_criteria
  belongs_to :study
  has_many :qc_metrics

  before_validation :generate_report_identifier, :if => :identifier_required?

  after_create :generate

  named_scope :for_report_page, lambda {|conditions|
    {
      :order => "id desc",
      :conditions => conditions,
      :joins  => :product_criteria
    }
  }

  validates_presence_of :product_criteria, :study, :state

  validates_inclusion_of :exclude_existing, :in => [true, false], :message => 'should be true or false.'

  handle_asynchronously :generate

  def to_param
    report_identifier
  end

  def product_id
    product.try(:id)
  end

  private

  def identifier_required?
    self.report_identifier.nil?
  end

  # Note: You won't be able to generate two reports for the
  # same product / study abbreviation combo within one second
  # of each other.
  def generate_report_identifier
    return true if study.nil? || product_criteria.nil?
    rid = [
      study.abbreviation,
      product_criteria.product.name,
      DateTime.now.to_formatted_s(:number)
    ].compact.join('_').downcase.gsub(/[^\w]/,'_')
    self.report_identifier = rid
  end

end
