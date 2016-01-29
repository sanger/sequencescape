class AddIllHtpPcrFreePipeline < ActiveRecord::Migration
  def up

  #IlluminaHtp::PlatePurposes.create_plate_purposes
  #IlluminaHtp::PlatePurposes.create_branches

    ActiveRecord::Base.transaction do |t|

      stock_name = 'PF Cherrypicked'

      branches =  [[ stock_name, 'PF Shear', 'PF Post Shear', 'PF Post Shear XP', 'PF AL Libs', 'PF Lib XP', 'PF Lib XP2', 'PF EM Pool', 'PF Lib Norm'],
        [ 'PF Lib XP2', 'PF MiSeq Stock', 'PF MiSeq QC']]

      plate_flow = [stock_name].concat(branches.flatten).uniq

      tube_flow = ['PF MiSeq Stock','PF MiSeq QC']

      IlluminaHtp::PlatePurposes.create_tube_flow(tube_flow)
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
