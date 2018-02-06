# Add some aker products for UAT

namespace :aker do
  desc 'Create a product and all of its associated data'
  task create_product: [:environment] do
    ActiveRecord::Base.transaction do
      product = Aker::Product.create(name: 'QC', description: 'Lorem Ipsum')
      process = Aker::Process.create(name: 'QC', turnaround_time: 5)

      Aker::ProductProcess.create(product: product, process: process, stage: 1)

      quantification = Aker::ProcessModule.create(name: 'Quantification')
      genotyping_cgp = Aker::ProcessModule.create(name: 'Genotyping CGP SNP')
      genotyping_ddd = Aker::ProcessModule.create(name: 'Genotyping DDD SNP')
      genotyping_humgen = Aker::ProcessModule.create(name: 'Genotyping HumGen SNP')

      process.process_module_pairings.build(to_step: quantification, default_path: true)
      process.process_module_pairings.build(to_step: genotyping_cgp)
      process.process_module_pairings.build(to_step: genotyping_ddd)
      process.process_module_pairings.build(to_step: genotyping_humgen)

      process.process_module_pairings.build(from_step: quantification, default_path: true)
      process.process_module_pairings.build(from_step: genotyping_cgp)
      process.process_module_pairings.build(from_step: genotyping_ddd)
      process.process_module_pairings.build(from_step: genotyping_humgen)

      process.process_module_pairings.build(from_step: quantification, to_step: genotyping_cgp, default_path: true)
      process.process_module_pairings.build(from_step: quantification, to_step: genotyping_ddd)
      process.process_module_pairings.build(from_step: quantification, to_step: genotyping_humgen)
      process.save
    end
  end

  desc 'Remove all Aker Products and its associated data'
  task remove_products: [:environment] do
    ActiveRecord::Base.transaction do
      Aker::Product.delete_all
      Aker::Process.delete_all
      Aker::ProductProcess.delete_all
      Aker::ProcessModule.delete_all
      Aker::ProcessModulePairing.delete_all
    end
  end
end
