module SampleManifestExcel
  class TagsUpdate
    include HashAttributes
    include ActiveModel::Validations

    set_attributes :sanger_sample_ids, :tag1_oligos, :tag2_oligos, :tag_group

    validates_presence_of :tag_group
    validate :tag_combination_is_unique
    validate :number_of_samples_and_tags_is_equal

    def initialize(attributes = {})
      create_attributes(attributes)
      @tag_group = TagGroup.find_or_create_by(name: 'Main')
    end

    def execute
      ActiveRecord::Base.transaction do
        sanger_sample_ids.each_with_index do |sanger_sample_id, index|
          aliquot = find_aliquot_by(sanger_sample_id: sanger_sample_id)
          add_tags(aliquot, tag1_oligos[index], tag2_oligos[index])
        end
      end
    end

    def find_aliquot_by(sanger_sample_id:)
      sample = Sample.find_by(sanger_sample_id: sanger_sample_id)
      Aliquot.find_by(sample_id: sample.id)
    end

    def find_tag_by(oligo:)
      tag_group.tags.find_or_create_by(oligo: oligo) do |tag|
        tag.map_id = tag_group.tags.count+1
      end
    end

    def add_tags(aliquot, oligo1, oligo2)
      aliquot.tag = find_tag_by(oligo: oligo1)
      aliquot.tag2 = find_tag_by(oligo: oligo2)
      aliquot.save
    end

    def tag_combination_is_unique
      tags_oligos = tag1_oligos.zip(tag2_oligos)
      errors.add(:tags_combinations, "are not unique") unless tags_oligos.length == tags_oligos.uniq.length
    end

    def number_of_samples_and_tags_is_equal
      unless (sanger_sample_ids.length == tag1_oligos.length && sanger_sample_ids.length == tag2_oligos.length)
        errors.add(:number_of_samples, "does not correspond to a number of tags")
      end
    end

  end
end