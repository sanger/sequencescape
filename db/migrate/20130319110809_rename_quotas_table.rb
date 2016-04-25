#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class RenameQuotasTable < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      rename_table :quotas, :quotas_bkp
      rename_table :request_quotas, :request_quotas_bkp
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      rename_table :quotas_bkp, :quotas
      rename_table :request_quotas_bkp, :request_quotas
    end
  end
end
