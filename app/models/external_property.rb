class ExternalProperty < ActiveRecord::Base
  belongs_to :propertied, :polymorphic => true
end
