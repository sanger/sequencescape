class Api::StudyIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::StudyIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        named_scope :including_associations_for_json, {
          :include => [
            :uuid_object, {
              :study_metadata => [:faculty_sponsor, :reference_genome, :study_type, :data_release_study_type],
              :roles => :users
            }
          ]
        }
      end
    end

    def render_class
      Api::StudyIO
    end
  end

  renders_model(::Study)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:ethically_approved)
  map_attribute_to_json_attribute(:state)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  extra_json_attributes do |object, json_attributes|
    json_attributes["abbreviation"] = object.abbreviation

    object.roles.each do |role|
      json_attributes[role.name.downcase.gsub(/\s+/, '_')] = role.user_role_bindings.map do |user_role|
        { :login => user_role.user.login, :email => user_role.user.email, :name  => user_role.user.name }.tap do
          json_attributes['updated_at'] ||= user_role.updated_at
          json_attributes['updated_at']   = user_role.updated_at if json_attributes['updated_at'] < user_role.updated_at
        end
      end
    end if object.respond_to?(:roles)
  end

  with_association(:study_metadata) do
    with_association(:faculty_sponsor, :lookup_by => :name) do
      map_attribute_to_json_attribute(:name, 'sac_sponsor')
    end

    with_association(:reference_genome, :lookup_by => :name) do
      map_attribute_to_json_attribute(:name, 'reference_genome')
    end
    map_attribute_to_json_attribute(:study_ebi_accession_number, 'accession_number')
    map_attribute_to_json_attribute(:study_description         , 'description')
    map_attribute_to_json_attribute(:study_abstract            , 'abstract')
    with_association(:study_type, :lookup_by => :name) do
      map_attribute_to_json_attribute(:name                    , 'study_type')
    end

    map_attribute_to_json_attribute(:study_project_id, 'ena_project_id')
    map_attribute_to_json_attribute(:study_study_title, 'study_title')
    map_attribute_to_json_attribute(:study_sra_hold, 'study_visibility')

    map_attribute_to_json_attribute(:contaminated_human_dna)
    map_attribute_to_json_attribute(:contains_human_dna)
    map_attribute_to_json_attribute(:commercially_available)
    with_association(:data_release_study_type, :lookup_by => :name ) do
      map_attribute_to_json_attribute(:name                    , 'data_release_sort_of_study')
    end
    map_attribute_to_json_attribute(:remove_x_and_autosomes?, 'remove_x_and_autosomes')

    map_attribute_to_json_attribute(:data_release_strategy)
    map_attribute_to_json_attribute(:ega_dac_accession_number)
    map_attribute_to_json_attribute(:array_express_accession_number)
    map_attribute_to_json_attribute(:ega_policy_accession_number)

    map_attribute_to_json_attribute(:data_release_timing)
    map_attribute_to_json_attribute(:data_release_delay_period)
    map_attribute_to_json_attribute(:data_release_delay_reason)
  end

  self.related_resources = [ :samples, :projects ]
end
