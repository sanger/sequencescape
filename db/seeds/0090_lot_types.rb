# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015,2016 Genome Research Ltd.

unless Rails.env.test?
  tp  = QcablePlatePurpose.find_or_create_by!(name: 'Tag Plate', target_type: 'Plate', default_state: 'created')
  rp  = QcablePlatePurpose.find_or_create_by!(name: 'Reporter Plate', target_type: 'Plate', default_state: 'created')
  itt = QcableTubePurpose.find_or_create_by!(name: 'Tag 2 Tube', target_type: 'Tube')
  pstp = QcablePlatePurpose.find_or_create_by!(name: 'Pre Stamped Tag Plate', target_type: 'Plate', default_state: 'available')
  btp  = QcablePlatePurpose.find_or_create_by!(name: 'Tag Plate - 384', target_type: 'Plate', default_state: 'available', size: 384)
  LotType.find_or_create_by!(name: 'IDT Tags',         template_class: 'TagLayoutTemplate', target_purpose: tp)
  LotType.find_or_create_by!(name: 'IDT Reporters',    template_class: 'PlateTemplate',     target_purpose: rp)
  LotType.find_or_create_by!(name: 'Tag 2 Tubes',      template_class: 'Tag2LayoutTemplate', target_purpose: itt)
  LotType.find_or_create_by!(name: 'Pre Stamped Tags', template_class: 'TagLayoutTemplate', target_purpose: pstp)
  LotType.find_or_create_by!(name: 'Tag 2 Tubes',      template_class: 'Tag2LayoutTemplate', target_purpose: itt)
  LotType.find_or_create_by!(name: 'Pre Stamped Tags - 384', template_class: 'TagLayoutTemplate', target_purpose: btp)
end
