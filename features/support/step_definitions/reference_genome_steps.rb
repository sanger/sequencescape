# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

Given /^a reference genome table$/ do
  FactoryGirl.create(:reference_genome, name: 'Danio_rerio (zv9)')
  FactoryGirl.create(:reference_genome, name: 'Mus_musculus (NCBIm37)')
  FactoryGirl.create(:reference_genome, name: 'Schistosoma_mansoni (20100601)')
  FactoryGirl.create(:reference_genome, name: 'Homo_sapiens (GRCh37_53)')
  FactoryGirl.create(:reference_genome, name: 'Staphylococcus_aureus (NCTC_8325)')
end
