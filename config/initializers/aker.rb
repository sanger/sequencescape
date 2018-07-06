# frozen_string_literal: true

Aker::Material.config = 
  %Q{
    sample_metadata.gender              <=   gender
    sample_metadata.donor_id            <=   donor_id
    sample_metadata.phenotype           <=   phenotype
    sample_metadata.sample_common_name  <=   common_name
    volume                               =>  volume
    concentration                        =>  concentration
    amount                               =>  amount
  }