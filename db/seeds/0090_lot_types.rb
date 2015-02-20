#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
tp = QcablePlatePurpose.create!(:name=>'Tag Plate', :target_type=>'Plate')
rp = QcablePlatePurpose.create!(:name=>'Reporter Plate', :target_type=>'Plate')
LotType.create!(:name=>'IDT Tags',      :template_class=>'TagLayoutTemplate', :target_purpose=>tp)
LotType.create!(:name=>'IDT Reporters', :template_class=>'PlateTemplate',     :target_purpose=>rp)
