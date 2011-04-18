class StudyRelationType < ActiveRecord::Base
  has_many :study_relations
  validates_uniqueness_of :name
  validates_uniqueness_of :reversed_name

  def relate_studies!(study, related_study)
    study.study_relations.create!(:related_study => related_study, :study_relation_type => self)
  end

  def self.names
    all.map { |srt| [srt.name, srt.reversed_name] }.flatten
  end


  def self.relate_studies_by_name!(name, study, related_study)
    relation_type = find_by_name(name)
    return relation_type.relate_studies!(study, related_study) if relation_type

    reversed = find_by_reversed_name(name)
    return reversed.relate_studies!(related_study, study) if reversed

    raise RuntimeError, "Can't find a study relation type with the name '#{name}'"
  end

  def self.unrelate_studies_by_name!(name, study, related_study)
    relation_type = find_by_name(name)
    relation = nil
    if relation_type
      relation = StudyRelation.find_by_study_relation_type_id_and_study_id_and_related_study_id(relation_type.id, study.id, related_study.id)
    else #  look for reverse one
      relation_type = find_by_reversed_name(name)
      relation = StudyRelation.find_by_study_relation_type_id_and_study_id_and_related_study_id(relation_type.id, related_study.id, study.id)
    end

    return relation.delete if relation

    raise RuntimeError, "Can't find a study relation type with the name '#{name}'"
  end
end
