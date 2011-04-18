Given /^a reference genome table$/ do
  Factory(:reference_genome, :name => "Danio_rerio (zv9)")
  Factory(:reference_genome, :name => "Mus_musculus (NCBIm37)")
  Factory(:reference_genome, :name => "Schistosoma_mansoni (20100601)")
  Factory(:reference_genome, :name => "Homo_sapiens (GRCh37_53)")
  Factory(:reference_genome, :name => "Staphylococcus_aureus (NCTC_8325)")
end
