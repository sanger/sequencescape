module Aker
  class Catalogue < ApplicationRecord
    validates :pipeline, :lims_id, presence: true

    has_many :products, foreign_key: :aker_catalogue_id, dependent: :destroy

    after_save :broadcast_catalogue

    def url
      'dev.psd.sanger.ac.uk'
    end

    def as_json(_options = {})
      {
        catalogue: {
          id: id,
          pipeline: pipeline,
          url: url,
          lims_id: lims_id,
          products: products
        }
      }
    end

    private

    def broadcast_catalogue
      Aker.broadcast_catalogue(self)
      true
    end
  end
end
