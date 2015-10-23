#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class QcReport < ActiveRecord::Base

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

        aasm_event :proceed_decision do
          transitions :from => :awaiting_proceed, :to => :complete
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
  has_one :product, :through => :product_criteria
  belongs_to :study
  has_many :qc_metrics

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

  def product_id
    product.try(:id)
  end

end
