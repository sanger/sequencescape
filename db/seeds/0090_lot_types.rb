tp = PlatePurpose.create!(:name=>'Tag Plate', :target_type=>'Plate')
rp = PlatePurpose.create!(:name=>'Reporter Plate', :target_type=>'Plate')
LotType.create!(:name=>'IDT Tags',      :template_class=>'TagLayoutTemplate', :target_purpose=>tp)
LotType.create!(:name=>'IDT Reporters', :template_class=>'PlateTemplate',     :target_purpose=>rp)
