#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class QcMetric < ActiveRecord::Base

  InvalidValue = Class.new(StandardError)

  QC_DECISION_TRANSLATION = {
    true => 'pass',
    false => 'fail'
  }

  PROCEED_TRANSLATION = {
    true => 'Y',
    false => 'N'
  }

  belongs_to :asset
  belongs_to :qc_report
  validates_presence_of :asset, :qc_report

  serialize :metrics

  named_scope :with_asset_ids, lambda {|ids| {:conditions=>{:asset_id=>ids}}}

  named_scope :for_product, lambda {|product|
      {
      :joins => {:qc_report=>:product_criteria},
      :conditions => {
        :product_criteria => { :product_id => product}
      }
    }
  }
  named_scope :most_recent_first, { :order => 'created_at DESC, id DESC' }

  def human_qc_decision
    QC_DECISION_TRANSLATION[qc_decision]
  end

  def human_qc_decision=(h_decision)
    self.qc_decision = human_to_bool(QC_DECISION_TRANSLATION,h_decision.downcase)
  end

  def human_proceed
    PROCEED_TRANSLATION[proceed]
  end

  def human_proceed=(h_proceed)
    return self.proceed = nil if h_proceed.blank?
    self.proceed = human_to_bool(PROCEED_TRANSLATION,h_proceed.upcase)
  end

  # The metric indicates that the sample has been progressed despite poor quality
  # || false ensures nil gets converted to a boolean
  def poor_quality_proceed
    ((! qc_decision) && proceed) || false
  end

  private

  def human_to_bool(hash,choice)
    hash.index(choice).tap do |v|
      raise(InvalidValue, value_error_message(choice,hash.values)) if v.nil?
    end
  end

  def value_error_message(decision, accepted)
    accepted = accepted.keys.to_sentence(:last_word_connector=>', or ',:two_words_connector=>' or ')
    "#{decision} is not an acceptable qc decision. Should be #{accepted}."
  end

end
