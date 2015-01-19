module ExtendedValidator::SpeciesValidator

  def validate(order)
    bad_samples = order.all_samples.select {|s| s.sample_metadata.sample_taxon_id != options[:taxon_id] }
    return true if bad_samples.empty?
    order.errors.add(:samples,"should have taxon_id #{options[:taxon_id]}")
    false
  end
end
