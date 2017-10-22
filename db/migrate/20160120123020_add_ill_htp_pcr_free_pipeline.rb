# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class AddIllHtpPcrFreePipeline < ActiveRecord::Migration
  def up
    # IlluminaHtp::PlatePurposes.create_plate_purposes
    # IlluminaHtp::PlatePurposes.create_branches

    ActiveRecord::Base.transaction do |_t|
      stock_name = 'PF Cherrypicked'

      branches = [[stock_name, 'PF Shear', 'PF Post Shear', 'PF Post Shear XP', 'PF Lib', 'PF Lib XP', 'PF Lib XP2', 'PF EM Pool', 'PF Lib Norm'],
        ['PF Lib XP2', 'PF MiSeq Stock', 'PF MiSeq QC'], ['PF MiSeq Stock', 'PF MiSeq QCR']]

      plate_flow = [stock_name, 'PF Shear', 'PF Post Shear', 'PF Post Shear XP', 'PF Lib', 'PF Lib XP', 'PF Lib XP2', 'PF EM Pool', 'PF Lib Norm']

      tube_flow = ['PF MiSeq Stock', 'PF MiSeq QC']

      IlluminaHtp::PlatePurposes.create_tube_flow(tube_flow)
      IlluminaHtp::PlatePurposes.create_tube_flow(['PF MiSeq QCR'])
      IlluminaHtp::PlatePurposes.create_plate_flow(plate_flow)
      branches.each do |branch|
        IlluminaHtp::PlatePurposes.create_branch(branch)
      end

      IlluminaHtp::PlatePurposes.create_qc_plate_for('PF EM Pool')
    end
  end

  def down
    ActiveRecord::Base.transaction do |t|
    end
  end
end
