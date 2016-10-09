# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015,2016 Genome Research Ltd.

tp  = QcablePlatePurpose.create!(:name => 'Tag Plate', :target_type => 'Plate', :default_state => 'created')
rp  = QcablePlatePurpose.create!(:name => 'Reporter Plate', :target_type => 'Plate', :default_state => 'created')
itt = QcableTubePurpose.create!(:name => 'Tag 2 Tube', :target_type => 'Tube')
pstp = QcablePlatePurpose.create!(:name => 'Pre Stamped Tag Plate', :target_type => 'Plate', :default_state => 'available')
LotType.create!(:name => 'IDT Tags',         :template_class => 'TagLayoutTemplate', :target_purpose => tp)
LotType.create!(:name => 'IDT Reporters',    :template_class => 'PlateTemplate',     :target_purpose => rp)
LotType.create!(:name => 'Tag 2 Tubes',      :template_class => 'Tag2LayoutTemplate', :target_purpose => itt)
LotType.create!(:name => 'Pre Stamped Tags', :template_class => 'TagLayoutTemplate', :target_purpose => pstp)
