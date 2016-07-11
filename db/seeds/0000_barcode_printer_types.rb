#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2015 Genome Research Ltd.

BarcodePrinterType1DTube.create(:name => "1D Tube", :printer_type_id => 2, label_template_name: 'ss_tube_label_template')
BarcodePrinterType96Plate.create(:name => "96 Well Plate", :printer_type_id => 1, label_template_name: 'ss_plate_label_template')
BarcodePrinterType384Plate.create(:name => "384 Well Plate", :printer_type_id => 6 )
