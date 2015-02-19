#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
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
