class FixTransferRequestReferences < ActiveRecord::Migration
  MODELS_AND_COLUMNS = {
    RequestType => :request_class_name,
    Request     => :sti_type
  }

  def self.change(from, to)
    ActiveRecord::Base.transaction do
      MODELS_AND_COLUMNS.each do |model, column|
        model.update_all(%Q{#{column}="#{to}"}, %Q{#{column}="#{from}"})
      end
    end
  end

  def self.up
    change('TransfertRequest', 'TransferRequest')
  end

  def self.down
    change('TransferRequest', 'TransfertRequest')
  end
end
