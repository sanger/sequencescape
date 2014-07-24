class Io::Project < Core::Io::Base
  set_model_for_input(::Project)
  set_json_root(:project)
  set_eager_loading { |model| model.include_project_metadata.include_roles }

  define_attribute_and_json_mapping(%Q{
                                              name  => name
                                          approved  => approved
                                             state  => state

             project_metadata.project_manager.name  => project_manager
                project_metadata.project_cost_code  => cost_code
                 project_metadata.funding_comments  => funding_comments
                    project_metadata.collaborators  => collaborators
          project_metadata.external_funding_source  => external_funding_source
       project_metadata.budget_division.name        => budget_division
    project_metadata.sequencing_budget_cost_centre  => budget_cost_centre
            project_metadata.project_funding_model  => funding_model

                                     roles_as_json  => roles
  })
end
