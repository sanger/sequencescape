# frozen_string_literal: true
# Tracks key value pair data imported from SNP. No longer being generated
# {Asset}: Location data imported via ETS
# {Sample}: Tracked genotyping status in external systems
# Only {Sample} still has hooks in the code
class ExternalProperty < ApplicationRecord
  belongs_to :propertied, polymorphic: true
end
