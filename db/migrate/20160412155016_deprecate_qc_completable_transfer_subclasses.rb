require './lib/request_class_deprecator'

class DeprecateQcCompletableTransferSubclasses < ActiveRecord::Migration # rubocop:todo Style/Documentation
  include RequestClassDeprecator

  def up
    ActiveRecord::Base.transaction do
      deprecate_class('IlluminaHtp::Requests::QcCompletableTransfer')
      deprecate_class('IlluminaHtp::Requests::PcrXpToStock')
      deprecate_class('IlluminaB::Requests::PcrXpToStock')
      deprecate_class('IlluminaHtp::Requests::LibPoolSsToLibPoolSsXp')
      deprecate_class('IlluminaHtp::Requests::LibPoolToLibPoolNorm')
      deprecate_class('IlluminaHtp::Requests::PcrToPcrXp')
      deprecate_class('IlluminaB::Requests::PcrToPcrXp')
      deprecate_class('IlluminaHtp::Requests::PcrXpToLibNorm')
    end
  end

  def down
  end
end
