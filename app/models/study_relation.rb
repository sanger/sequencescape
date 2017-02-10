# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class StudyRelation < ActiveRecord::Base
  belongs_to :study
  belongs_to :related_study, class_name: 'Study'
  belongs_to :study_relation_type

  validates_presence_of :study
  validates_presence_of :related_study
  validates_presence_of :study_relation_type

  validates_uniqueness_of :study_relation_type_id, scope: [:study_id, :related_study_id]

  delegate :name, :reversed_name, to: :study_relation_type

  module Associations
    def self.included(base)
      # Related studies
      base.has_many :study_relations
      base.has_many :related_studies, through: :study_relations, class_name: 'Study'
      # Inverse
      base.has_many :reversed_study_relations, class_name: 'StudyRelation', foreign_key: :related_study_id
      base.has_many :reversed_related_studies, through: :reversed_study_relations, class_name: 'Study', source: :study
    end

    # related studies
    def related_studies_for(relation_type)
      r_id = relation_type.is_a?(StudyRelationType) ? relation_type.id : relation_type
      study_relations.select { |r| r.study_relation_type_id == r_id }
    end

    def relations_for_study(study)
      s_id = study.is_a?(Study) ? study.id : id
      study_relations.select { |r| r.related_study_id == s_id }
    end

    def relation_types_for_study(study)
      relations_for_study(study).map(&:study_relation_type)
    end

    # reverse related studies
    def reversed_related_studies_for(relation_type)
      r_id = relation_type.is_a?(StudyRelationType) ? relation_type.id : relation_type
      reversed_study_relations.select { |r| r.study_relation_type_id == r_id }
    end

    def reversed_relations_for_study(study)
      s_id = study.is_a?(Study) ? study.id : id
      reversed_study_relations.select { |r| r.related_study_id == s_id }
    end

    def reversed_relation_types_for_study(study)
      reversed_relations_for_study(study).map(&:study_relation_type)
    end
  end
end
