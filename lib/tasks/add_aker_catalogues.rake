# Add some aker products for UAT

namespace :aker do
  desc 'Create a product and all of its associated data'
  task create_catalogue: [:environment] do
    ActiveRecord::Base.transaction do
      catalogue = Aker::Catalogue.create(pipeline: 'WGS', lims_id: 'SQSC')
      product = Aker::Product.create(name: 'QC', description: 'Lorem Ipsum', requested_biomaterial_type: 'blood', product_class: 'genotyping', catalogue: catalogue)
      process = Aker::Process.create(name: 'QC', tat: 5)

      Aker::ProductProcess.create(product: product, process: process, stage: 1)

      quantification = Aker::ProcessModule.create(name: 'Quantification')
      genotyping_cgp = Aker::ProcessModule.create(name: 'Genotyping CGP SNP')
      genotyping_ddd = Aker::ProcessModule.create(name: 'Genotyping DDD SNP')
      genotyping_humgen = Aker::ProcessModule.create(name: 'Genotyping HumGen SNP')

      process.process_module_pairings.build(to_step: quantification, default_path: true)
      process.process_module_pairings.build(to_step: genotyping_cgp)
      process.process_module_pairings.build(to_step: genotyping_ddd)
      process.process_module_pairings.build(to_step: genotyping_humgen)

      process.process_module_pairings.build(from_step: quantification)
      process.process_module_pairings.build(from_step: genotyping_cgp)
      process.process_module_pairings.build(from_step: genotyping_ddd)
      process.process_module_pairings.build(from_step: genotyping_humgen, default_path: true)

      process.process_module_pairings.build(from_step: quantification, to_step: genotyping_cgp, default_path: true)
      process.process_module_pairings.build(from_step: quantification, to_step: genotyping_ddd)
      process.process_module_pairings.build(from_step: quantification, to_step: genotyping_humgen)
      process.save
    end
  end

  desc 'Remove all Aker Catalogues and its associated data'
  task remove_catalogues: [:environment] do
    ActiveRecord::Base.transaction do
      Aker::Catalogue.delete_all
      Aker::Product.delete_all
      Aker::Process.delete_all
      Aker::ProductProcess.delete_all
      Aker::ProcessModule.delete_all
      Aker::ProcessModulePairing.delete_all
    end
  end
end
