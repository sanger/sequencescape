module StudyReport::PlatePurposesFinder

 STOCK_PLATE_PURPOSES_NAMES = ['Stock Plate','Stock RNA Plate']
 ACT_AS_STOCK_PLATE_PURPOSES_NAMES = ['Pre-Extracted Plate']
 ALIQUOT_PLATE_PURPOSES_NAMES = ['Aliquot 1','Aliquot 2','Aliquot 3','Aliquot 4','Aliquot 1']


  def self.included(klass)
    klass.instance_eval do
      scope :stock_plate_purposes_for_qc_reports, -> { where(name: STOCK_PLATE_PURPOSES_NAMES) }
      scope :aliquots_and_act_as_stock_plate_purposes_for_qc_reports, -> { where(name: ALIQUOT_PLATE_PURPOSES_NAMES.concat(ACT_AS_STOCK_PLATE_PURPOSES_NAMES))}
      scope :stock_and_act_as_stock_plate_purposes_for_qc_reports, -> { where(name: STOCK_PLATE_PURPOSES_NAMES.concat(ACT_AS_STOCK_PLATE_PURPOSES_NAMES))}
    end
  end
end
