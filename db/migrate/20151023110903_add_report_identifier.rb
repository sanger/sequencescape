#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddReportIdentifier < ActiveRecord::Migration
  def self.up
    add_column :qc_reports, :report_identifier, :string, :after => :id, :null => false
    QcReport.find_each {|r| r.send(:generate_report_identifier); r.save }
    add_index :qc_reports, :report_identifier, :unique => true
  end

  def self.down
    remove_index :qc_reports, :report_identifier
    remove_column :qc_reports, :report_identifier
  end
end
