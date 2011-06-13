ActionController::Routing::Routes.draw do |map|
  map.resources :reference_genomes
  map.resources :barcode_printers
  map.resources :submission_workflows
  map.resources :request_types

  map.resources :robot_verifications, :collection => {:submission => [:post, :get], :download => [:post]}
  map.resources :projects, :has_many => :studies, :member => { :related_studies => :get, :collaborators => :get, :follow => :get, :grant_role => :post, :remove_role => :post  } do |project|
    project.resources :workflows, :only => :none  do |workflow|
      workflow.resources :quotas, :controller => "projects/workflows/quotas", :only => [],
                         :collection => { :all => :get, :send_request => :post, :update_request => :get }
    end
    project.resources :billing_events, :controller => "projects/billing_events", :only => [:index, :show, :new, :create]
  end

  #### NPG start ####
  map.with_options(:path_prefix => '/npg_actions', :conditions => { :method => :post, :format => :xml }) do |npg|
    npg.with_options(:controller => 'npg_actions/assets') do |assets|
      assets.pass_qc_state 'assets/:id/pass_qc_state', :action => 'pass'
      assets.fail_qc_state 'assets/:id/fail_qc_state', :action => 'fail'
    end
  end
  #### NPG end ####

  map.resources :items
  map.resources :batches, :member => {:print_labels => :get, :print_stock_labels => :get, :print_plate_labels => :get, :filtered => :get, :swap => :post, :gwl_file => :get} do |batch|
    batch.resources :requests, :controller => "batches/requests"
    batch.resources :comments, :controller => "batches/comments"
  end

  map.release_batch 'pipelines/release/:id', :action => 'release', :controller =>'pipelines'
  map.finish_batch 'pipelines/finish/:id', :action => 'finish', :controller =>'pipelines'
  map.connect "run/:run", :controller => "items", :action => "run_lanes"
  map.connect "run/:run.json", :controller => "items", :action => "run_lanes", :format => "json"
  map.connect "run/:run.xml", :controller => "items", :action => "run_lanes", :format => "xml"
  map.login "/login", :controller => "sessions", :action => "login"
  map.logout "/logout", :controller => "sessions", :action => "logout"

  # Main objects
  map.resources :events
  map.resources :sources
  map.resources :samples, :has_many => :assets, :member => {:filtered_move => :get, :move => :post, :history => :get }, :collection =>{ :move_spreadsheet => :get, :move_upload => :post, :move_upload_do => :post}
  map.resources :samples, :collection => { :upload => :get, :review => :post } do |sample|
    sample.resources :comments, :controller => "samples/comments"
    sample.resources :studies, :controller => "samples/studies"
  end

  map.connect '/taxon_lookup_by_term/:term', :controller => "samples", :action => "taxon_lookup"
  map.connect '/taxon_lookup_by_id/:id', :controller => "samples", :action => "taxon_lookup"

  map.resources :sample_group
  map.connect '/studies/:study_id/workflows/:workflow_id/summary_detailed/:id', :controller => "studies/workflows", :action => "summary_detailed"
  map.connect 'studies/accession/:id', :controller =>"studies", :action =>"accession"
  map.connect 'studies/policy_accession/:id', :controller =>"studies", :action =>"policy_accession"
  map.connect 'studies/dac_accession/:id', :controller =>"studies", :action =>"dac_accession"
  map.study_show_accession 'studies/accession/show/:id', :controller =>"studies", :action =>"show_accession"
  map.study_show_dac_accession 'studies/accession/dac/show/:id', :controller =>"studies", :action =>"show_dac_accession"
  map.study_show_policy_accession 'studies/accession/policy/show/:id', :controller =>"studies", :action =>"show_policy_accession"
  #map.connect 'studies/accession/submission/:id', :controller =>"studies", :action =>"show_submission" doesn't exist anymore
  map.connect 'samples/accession/:id', :controller =>"samples", :action =>"accession"
  map.connect 'samples/accession/show/:id', :controller =>"samples", :action =>"show_accession"
  map.destroy_sample 'samples/destroy/:id', :controller => "samples", :action => "destroy"
  map.sample_show_accession 'samples/accession/show/:id', :controller =>"samples", :action =>"show_accession"

  map.connect '/taxon_lookup_by_term/:term', :controller => "samples", :action => "taxon_lookup"
  map.connect '/taxon_lookup_by_id/:id', :controller => "samples", :action => "taxon_lookup"

  map.resources :studies, :has_many => :assets, :collection => {:study_list => :get},
    :member => { :study_reports => [:get], :sample_manifests => :get, :suppliers => :get, :assembly => [:put, :get], :new_plate_submission => :get, :create_plate_submission => :post, :close => :get, :open => :get, :follow => :get, :projects => :get, :study_status => :get, :collaborators => :get, :properties => :get, :state => :get, :grant_role => :post, :remove_role => :post , :related_studies => :get, :relate_study => :post, :unrelate_study => :post} do |study|
    study.resources :sample_registration, :controller => "studies/sample_registration",
      :only => [:index, :new, :create], :collection => {:new => [:get, :post], :upload => :get}
    study.resources :samples, :controller => "studies/samples"
    study.resources :events, :controller => "studies/events"

    study.resources :requests, :member => { :reset => :post, :cancel => :get }
    study.resources :comments, :controller => "studies/comments"
    study.resources :sample_groups, :controller => "studies/sample_groups", :collection => {:sort => :get}, :member => {:manage => :get, :add_samples => :post, :remove_samples => :delete, :find => [:get, :post]} do |sample_group|
      sample_group.resources :comments, :controller => "sample_groups/comments"
    end
    study.resources :asset_groups, :controller => "studies/asset_groups", :member => {:search => :post, :add => :post, :print => :get, :print_labels => :post, :printing => :get}

    study.resources :plates, :controller => "studies/plates", :except => [:destroy], :collection => {:view_wells => :post, :asset_group => :post, :show_asset_group => :get}, :member => {:remove_wells => :post} do |plate|
      plate.resources :wells, :except => [:destroy, :edit], :controller => "studies/plates/wells"
    end

    study.resources :workflows, :controller => "studies/workflows", :member => { :summary => :get, :show_summary => :get } do |workflow|
      workflow.resources :submissions, :controller => "studies/workflows/submissions", :collection => { :info => [:get, :put], :template_chooser => :get, :new => [:get, :put] }
      workflow.resources :assets, :collection => { :print => :post }
    end

    study.resources :documents, :controller => "studies/documents", :only => [:index, :new, :create, :show, :destroy]

  end

  map.resources :properties  do |property|
    property.resources :documents, :controller => "properties/documents", :only => [:show]
  end

  map.resources :documents, :controller => 'properties/documents', :only => [ :show ]

  
  #Same path but two different actions. GET for put parameter in the form and show the error. PUT for the action.
  map.filter_change_decision_request 'requests/:id/change_decision', :controller => 'requests', :action => 'filter_change_decision', :conditions => { :method => :get }
  map.change_decision_request        'requests/:id/change_decision', :controller => 'requests', :action => 'change_decision',        :conditions => { :method => :put }

  #Same path but two different actions. GET for put parameter in the form and show the error. PUT for the action.
  map.filter_change_name_rename      'renames/:id/change_name', :controller => 'renames', :action => 'filter_change_name', :conditions => { :method => :get }
  map.change_name_rename             'renames/:id/change_name', :controller => 'renames', :action => 'change_name',        :conditions => { :method => :put }

  
  map.resources :requests,
                :has_many => :batches,
                :member => { :copy => :get, :cancel => :get, :print => :get, :history => :get },
                :collection => { :incomplete_requests_for_family => :get, :pending => :get, :get_children_requests => :get, :mpx_requests_details => :get} do |request|
    request.resources :comments, :controller => "requests/comments"
  end

  map.resources :items, :only => :none, :shallow => true do |item|
    item.resource :request, :only => [:new, :create]
  end

  map.resources :annotations

  map.study_workflow_status "studies/:study_id/workflows/:id", :controller => "study_workflows", :action => "show"

  map.resources :searches, :only => [:index]

  # Administrative things
  map.admin "admin", :controller => "admin", :action => "index"
  map.resources :custom_texts, :controller => "admin/custom_texts", :path_prefix => "/admin"
  map.resources :settings, :controller => "admin/settings", :path_prefix => "/admin", :collection => { :reset => :get, :apply => :get }
  map.resources :studies, :controller => "admin/studies", :path_prefix => "/admin", :member => { :managed_update => :put }, :collection => {:index => :get, :reset_quota => :post}
  map.resources :projects, :controller => "admin/projects", :path_prefix => "/admin", :member => { :managed_update => :put }, :collection => {:index => :get, :reset_quota => :post}
  map.resources :plate_purposes, :controller => "admin/plate_purposes", :path_prefix => "/admin"
  map.resources :faculty_sponsors, :controller => "admin/faculty_sponsors", :path_prefix => "/admin"
  map.resources :change_tags, :controller => "admin/change_tags", :path_prefix => "/admin", :collection => { :lookup => :get, :bulk_update => :put}

  map.resources :users, :controller => "admin/users", :path_prefix => "/admin",
    :collection => { :filter => :get }, :member => { :switch => :get, :grant_user_role => :post, :remove_user_role => :post }
  map.resources :profile, :controller => "users",:member => {:study_reports => :get, :projects => :get }, :only => [:show, :edit, :update, :projects]
  map.resources :roles, :path_prefix => "/admin", :shallow => true do |role|
    role.resources :users, :controller => "roles/users"
  end
  map.resources :robots, :controller => "admin/robots", :path_prefix => "/admin", :has_many => :robot_properties

  ## From pipelines


  map.resources :verifications, :collection => {:input => :get, :verify => :post }
  map.resources :plate_templates

  map.connect 'implements/print_labels', :controller => 'implements', :action => 'print_labels'
  map.resources :implements
  map.resources :pico_sets, :member => { :analyze => :get, :score => :post, :normalise_plate => :get}, :collection => { :create_from_stock => :get }
  map.resources :gels, :member => { :show => :get, :update => :post}, :collection => { :lookup => :post, :find => :get }

  map.resources :locations

  map.resources :request_information_types

  map.logout "/logout", :controller => "sessions", :action => "logout"
  map.login "/login", :controller => "sessions", :action => "login"

  # TODO: Decide if this route and the associated controller are actually required (used by library prep pipeline)
  map.connect 'pipelines/assets/new/:id', :controller => 'pipelines/assets', :action => 'new', :conditions => { :method => :get }

  map.resources :pipelines, :member => { :reception => :get, :show_comments => :get}, :collection => { :update_priority => :post }

  map.resource :search, :controller => 'search', :only => [:new, :index]

  map.resources :errors

  map.resources :events

  map.connect 'batches/all', :controller => 'batches', :action => 'all'
  map.connect 'batches/released', :controller => 'batches', :action => 'released'
  map.connect 'batches/released/clusters', :controller => 'batches', :action => 'released'


  map.resources :items, :collection => { :samples_for_autocomplete => :get }

  map.connect 'workflows/refresh_sample_list', :controller => 'workflows', :action => 'refresh_sample_list'

  map.resources :workflows

  map.resources :tasks
  map.resources :asset_audits

  map.connect 'assets/snp_import', :controller => 'assets', :action => 'snp_import'
  map.assets_lookup 'assets/lookup', :controller => 'assets', :action => 'lookup'
  map.connect 'assets/receive_barcode', :controller => 'assets', :action => 'receive_barcode'
  map.connect 'assets/import_from_snp', :controller => 'assets', :action => 'import_from_snp'
  map.connect 'assets/confirm_reception', :controller => 'assets', :action => 'confirm_reception'
  map.connect 'assets/combine', :controller => 'assets', :action => 'combine'
  map.connect 'assets/get_plate_layout', :controller => 'assets', :action => 'get_plate_layout'
  map.connect 'assets/create_plate_layout', :controller => 'assets', :action => 'create_plate_layout'
  map.connect 'assets/make_plate_from_rack', :controller => 'assets', :action => 'make_plate_from_rack'

  map.controller 'assets/find_by_barcode', :controller => 'assets', :action => 'find_by_barcode'
  
  map.lab_view "lab_view", :controller => 'assets', :action => 'lab_view'  

  map.resources :families
  map.resources :tag_groups, :except => [:destroy] do |tag|
    tag.resources :tags, :except => [:destroy, :index, :create, :new]
  end
  
  

  map.resources :assets, :has_many => :assets, :collection => { :snp_register => :get, :reception => :get, :print_labels => :post}, :member => { :parent_assets => :get, :child_assets => :get, :show_plate => :get, :new_request => :get, :create_request => :post, :summary => :get, :close => :get, :print => :get, :print_items => :post, :submit_wells => :get, :create_wells_group => :post, :history => :get, :filtered_move => :get, :move => :post, :move_to_2D => :get,  :complete_move_to_2D => :post} do |asset|
    asset.resources :comments, :controller => "assets/comments"
  end
  
  map.resources :plates, :collection => { :upload_pico_results => :post, :create => :post, :to_sample_tubes => :get, :create_sample_tubes => :post }


  map.resources :pico_set_results, :collection => {:upload_pico_results => :post, :create => :post}

  map.resources :receptions, :collection => { :snp_register => :get, :reception => :get, :snp_import => :get, :receive_snp_barcode => :get}

  map.with_options(:controller => 'sequenom') do |sequenom|
    sequenom.sequenom_root 'sequenom/index', :action => 'index', :conditions => { :method => :get }
    sequenom.sequenom_search 'sequenom/search', :action => 'search', :conditions => { :method => :post }
    sequenom.sequenom_plate 'sequenom/:id', :action => 'show', :conditions => { :method => :get }, :requirements => { :id => /\d+/ }
    sequenom.sequenom_update 'sequenom/:id', :action => 'update', :conditions => { :method => :put }, :requirements => { :id => /\d+/ }
    sequenom.sequenom_quick_update 'sequenom/quick', :action => 'quick_update', :conditions => { :method => :post }
  end
  
  map.resources :sequenom_qc_plates, :only => [ :new, :create, :index]
  
  map.resources :pico_dilutions

  map.resources :study_reports
  map.resources :sample_logistics, :collection => { :lab => :get, :qc_overview => :get }

  ### Pulldown ###
  map.with_options(:namespace => "pulldown/", :path_prefix => "/pulldown") do |pulldown|
    pulldown.resources :plates, :collection => { :lookup_plate_purposes => :get }
    pulldown.resources :validates, :collection => { :source_plate_type => :get, :target_plate_type => :get, :validate_plates => :post }
  end

  
  

  ### Standard routes
  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "studies"

  ######  API  #####
  map.with_options(:path_prefix => "/#{API_VERSION}") do |api|
    # Some of our resources are read-only (default behaviour but this just makes it clearer) ...
    api.with_options(:read_only => true) do |read_only|
      read_only.model :asset_audits, :controller => "api/asset_audits"
      read_only.model :asset_links, :controller => "api/asset_links"
      read_only.model :batch_requests, :controller => "api/batch_requests"
      read_only.asset :batches, :controller => "api/batches"
      read_only.model :billing_events, :controller => "api/billing_events"
      read_only.model :events, :controller => "api/events"
      read_only.asset :lanes, :controller => "api/lanes"
      read_only.asset :library_tubes, :controller => "api/library_tubes" do |library_tube|
        library_tube.asset :lanes, :controller => "api/lanes"
        library_tube.model :requests, :controller => "api/requests"
      end
      read_only.asset :multiplexed_library_tubes, :controller => "api/multiplexed_library_tubes"
      read_only.asset :pulldown_multiplexed_library_tubes, :controller => "api/pulldown_multiplexed_library_tubes"
      read_only.model :plate_purposes, :controller => "api/plate_purposes"
      read_only.asset :plates, :controller => "api/plates"
      read_only.model :quotas, :controller => "api/quotas"
      read_only.asset :sample_tubes, :controller => "api/sample_tubes" do |sample_tube|
        sample_tube.asset :library_tubes, :controller => "api/library_tubes"
        sample_tube.model :requests, :controller => "api/requests"
      end
      read_only.model :study_samples, :controller => "api/study_samples"
      read_only.model :submissions, :controller => "api/submissions"
      
      read_only.asset :tag_instances, :controller => "api/tag_instances"
      read_only.model :tags, :controller => "api/tags"
      read_only.asset :wells, :controller => "api/wells"
    end

    # ... others are CRUD resources ...
    api.with_options(:read_only => false) do |crud|
      crud.model :projects, :controller => "api/projects" do |project|
        project.model :studies, :controller => "api/studies"
      end  
      crud.model :requests, :controller => "api/requests"
      crud.model :samples, :controller => "api/samples" do |smp|
        smp.asset :sample_tubes, :controller => "api/sample_tubes", :read_only => true
      end
      crud.model :studies, :controller => "api/studies" do |study|
        study.model :samples, :controller => "api/samples"
        study.model :projects, :controller => "api/projects"
      end  
    end

    # ... and some are specialised (but should not be!)
    
  end
  #### API end ####
  
  ### SDB ###
  map.with_options(:namespace => "sdb/", :path_prefix => "/sdb") do |sdb|
    sdb.resources :sample_manifests, :collection => {:upload => :post} ,:member => {:export => :get, :uploaded_spreadsheet => :get}
    #/:relative_root/:class/:attachment/:id?style=:style
    sdb.resources :suppliers, :member => {:sample_manifests => :get, :studies => :get}
    sdb.connect "/", :controller => "home"
  end
  
  
  # Install the default routes as the lowest priority.
  map.connect ":controller/:action/:id"
  map.connect ":controller/:action/:id.:format"
end
