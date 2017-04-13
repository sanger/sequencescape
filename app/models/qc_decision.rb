# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class QcDecision < ActiveRecord::Base
  include Uuid::Uuidable

  class QcDecisionQcable < ActiveRecord::Base
    self.table_name = ('qc_decision_qcables')

    belongs_to :qcable
    belongs_to :qc_decision, inverse_of: :qc_decision_qcables

    validates :qcable, presence: true
    validates :qc_decision, presence: true
    validates :decision, presence: true

    validates_inclusion_of :decision, in: Qcable.aasm.state_machine.events.map { |i, _j| i.to_s }

    after_create :make_decision

    private

    def make_decision
      qcable.send(:"#{decision}!")
    end
  end

  belongs_to :user
  belongs_to :lot

  has_many :qc_decision_qcables, class_name: 'QcDecision::QcDecisionQcable', inverse_of: :qc_decision
  has_many :qcables, through: :qc_decision_qcables

  validates_presence_of :user
  validate :user_has_permission, if: :user

  def decisions=(decisions)
    qc_decision_qcables.build(decisions)
  end

  private

  def user_has_permission
    return true if user.qa_manager?
    errors.add(:user, 'does not have permission to make qc decisions.')
    false
  end
end
