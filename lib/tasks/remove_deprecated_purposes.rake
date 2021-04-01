# frozen_string_literal: true

namespace :remove do
  desc 'Update the `type` of purposes where custom behaviour has been removed'
  task deprecated_purposes: :environment do
    # Hash of classes to change in the format from => to
    {
      'IlluminaC::AlLibsTaggedPurpose' => 'PlatePurpose',
      'IlluminaC::LibPcrPurpose' => 'PlatePurpose',
      'IlluminaC::LibPcrXpPurpose' => 'PlatePurpose',
      'IlluminaC::QcPoolPurpose' => 'Tube::Purpose',
      'IlluminaC::StockPurpose' => 'PlatePurpose::Input',
      'IlluminaHtp::FinalPlatePurpose' => 'PlatePurpose',
      'IlluminaHtp::InitialDownstreamPlatePurpose' => 'PlatePurpose',
      'IlluminaHtp::NormalizedPlatePurpose' => 'PlatePurpose',
      'IlluminaHtp::PooledPlatePurpose' => 'PlatePurpose',
      'IlluminaHtp::PostShearQcPlatePurpose' => 'PlatePurpose',
      'IlluminaHtp::TransferablePlatePurpose' => 'PlatePurpose',
      'Pulldown::InitialDownstreamPlatePurpose' => 'PlatePurpose',
      'Pulldown::InitialPlatePurpose' => 'PlatePurpose',
      'Pulldown::LibraryPlatePurpose' => 'PlatePurpose',
      'IlluminaB::MxTubePurpose' => 'Tube::StandardMx',
      'IlluminaHtp::DownstreamPlatePurpose' => 'PlatePurpose',
      'IlluminaHtp::MxTubeNoQcPurpose' => 'IlluminaHtp::MxTubePurpose',
      'IlluminaC::MxTubePurpose' => 'IlluminaHtp::MxTubePurpose'
    }.each do |from, to|
      puts "Migrating from #{from} to #{to}"
      purposes = Purpose.where(type: from)
      puts "- Updating #{purposes.count} entries"
      purposes.each do |purpose|
        puts "- Updating #{purpose}"
        purpose.update!(type: to)
      end
    end
  end
end
