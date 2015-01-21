module ExtendedValidator::SpeciesValidator

  def validate_order(order)
    bad_samples = order.all_samples.select {|s| s.sample_metadata.sample_taxon_id != options[:taxon_id] }
    return true if bad_samples.empty?
    order.errors.add(:samples,"should have taxon_id #{options[:taxon_id]}: problems with #{bad_samples.map(&:sanger_sample_id).to_sentence}.")
    false
  end
end
