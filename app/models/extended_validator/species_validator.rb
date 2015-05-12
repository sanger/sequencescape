#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module ExtendedValidator::SpeciesValidator

  def validate_order(order)
    bad_samples = order.all_samples.select {|s| s.sample_metadata.sample_taxon_id != options[:taxon_id] }
    return true if bad_samples.empty?
    order.errors.add(:samples,"should have taxon_id #{options[:taxon_id]}: problems with #{bad_samples.map(&:sanger_sample_id).to_sentence}.")
    false
  end
end
