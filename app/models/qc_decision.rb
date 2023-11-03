# frozen_string_literal: true
class QcDecision < ApplicationRecord
  include Uuid::Uuidable

  class QcDecisionQcable < ApplicationRecord
    self.table_name = ('qc_decision_qcables')

    belongs_to :qcable
    belongs_to :qc_decision, inverse_of: :qc_decision_qcables

    validates :qcable, presence: true
    validates :qc_decision, presence: true
    validates :decision, presence: true

    validates :decision, inclusion: { in: Qcable.aasm.state_machine.events.map { |i, _j| i.to_s } }

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

  validates :user, presence: true
  validate :user_has_permission, if: :user

  def decisions=(decisions)
    qc_decision_qcables.build(decisions)
  end

  private

  def user_has_permission
    return true if Ability.new(user).can? :create, self

    errors.add(:user, 'does not have permission to make qc decisions.')
    false
  end
end
