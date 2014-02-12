class QcDecision < ActiveRecord::Base

  class QcDecisionQcable < ActiveRecord::Base

    set_table_name('qc_decision_qcables')

    belongs_to :qcable
    belongs_to :qc_decision, :inverse_of=>:qc_decision_qcables

    validates_presence_of :qcable, :qc_decision, :decision

    validates_inclusion_of :decision, :in => Qcable.aasm_events.map {|i,j| i.to_s }

    after_create :make_decision

    private

    def make_decision
      qcable.send(:"#{decision}")
    end
  end

  belongs_to :user
  belongs_to :lot

  has_many :qc_decision_qcables, :class_name => 'QcDecision::QcDecisionQcable', :inverse_of => :qc_decision
  has_many :qcables, :through => :qc_decision_qcables

  validates_presence_of :user

  def decisions=(decisions)
    self.qc_decision_qcables.build(decisions)
  end
end
