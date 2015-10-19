#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class QcReport < ActiveRecord::Base

  include AASM

  module StateMachine
    def self.included(base)
      base.class_eval do

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

        aasm_event :proceed_decision do
          transitions :from => :awaiting_proceed, :to => :complete
        end

        aasm_initial_state :queued

      end
    end
  end

  module ReportBehaviour
    def generate_report
      ActiveRecord::Base.transaction do
        study.each_well_for_qc_report(exclude_existing) do |asset|
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
  belongs_to :study
  has_many :qc_metrics

  validates_presence_of :product_criteria, :study, :state

  validates_inclusion_of :exclude_existing, :in => [true, false]

end
