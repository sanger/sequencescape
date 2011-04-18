module StudyReport::AssetDetails
  
  def qc_report
    qc_data = {
      :supplier_volume => 0
    }
    
    if self.sample
      if self.sample.empty_supplier_sample_name
        supplier_sample_name = "Blank"
      else
        supplier_sample_name = self.sample.sample_metadata.supplier_name || self.sample.sanger_sample_id || self.sample.name
      end
      
      qc_data.merge!({
        :supplier             => self.sample.try(:sample_manifest).try(:supplier).try(:name),
        :sample_name          => supplier_sample_name,
        :sanger_sample_id     => self.sample.sanger_sample_id,
        :control              => self.sample.control,
        :status               => (self.sample.updated_by_manifest ? 'Updated by manifest' : 'Awaiting manifest') ,

        :supplier_gender      => self.sample.sample_metadata.gender,
        :cohort               => self.sample.sample_metadata.cohort,
        :country_of_origin    => self.sample.sample_metadata.country_of_origin,
        :geographical_region  => self.sample.sample_metadata.geographical_region,
        :ethnicity            => self.sample.sample_metadata.ethnicity,
        :dna_source           => self.sample.sample_metadata.dna_source,
        :is_resubmitted       => self.sample.sample_metadata.is_resubmitted
      })
    end
    
    qc_data
  end
  
end
