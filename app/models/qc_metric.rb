#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class QcMetric < ActiveRecord::Base

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

  def human_qc_decision
    QC_DECISION_TRANSLATION[qc_decision]
  end

  def human_proceed
    PROCEED_TRANSLATION[proceed]
  end

end
