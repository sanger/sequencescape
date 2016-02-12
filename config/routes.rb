#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014 Genome Research Ltd.
Sequencescape::Application.routes.draw do
  root to:'studies#index'
  resource :home, :only => [:show]

  mount Api::RootService.new => '/api/1'

  resources :samples do

    resources :assets
    resources :comments
    resources :studies

    member do
      get :history
    end

    collection do
      get :upload
      post :review
    end
  end

  resources :projects do
    resources :studies
    member do
      get :related_studies
      get :collaborators
      get :follow
      post :grant_role
      post :remove_role
    end
  end

  match '/login' => 'sessions#login', :as => :login
  match '/logout' => 'sessions#logout', :as => :logout

  resources :reference_genomes
  resources :barcode_printers

  resources :robot_verifications do
    collection do
      post :submission
      get :submission
      post :download
    end
  end

  scope 'npg_actions', :module => 'npg_actions' do
    resources :assets, :only => [] do
      post :pass_qc_state, :action => :pass, :format => :xml
      post :fail_qc_state, :action => :fail, :format => :xml
    end
  end

  resources :items

  resources :batches do
    resources :requests
    resources :comments

    member do
      get :print_labels
      get :print_stock_labels
      get :print_plate_labels
      get :filtered
      post :swap
      get :gwl_file
    end

  end

  match 'batches/released/clusters' => 'batches#released'
  match 'batches/released/:id' => 'batches#released'

  match 'pipelines/release/:id' => 'pipelines#release', :as => :release_batch
  match 'pipelines/finish/:id' => 'pipelines#finish', :as => :finish_batch
  match 'run/:run' => 'items#run_lanes'
  match 'run/:run.json' => 'items#run_lanes', :format => 'json'
  match 'run/:run.xml' => 'items#run_lanes', :format => 'xml'

  resources :events
  resources :sources

  match '/taxon_lookup_by_term/:term' => 'samples#taxon_lookup'
  match '/taxon_lookup_by_id/:id' => 'samples#taxon_lookup'

  match '/studies/:study_id/workflows/:workflow_id/summary_detailed/:id' => 'studies/workflows#summary_detailed'
  match 'studies/accession/:id' => 'studies#accession'
  match 'studies/policy_accession/:id' => 'studies#policy_accession'
  match 'studies/dac_accession/:id' => 'studies#dac_accession'
  match 'studies/accession/show/:id' => 'studies#show_accession', :as => :study_show_accession
  match 'studies/accession/dac/show/:id' => 'studies#show_dac_accession', :as => :study_show_dac_accession
  match 'studies/accession/policy/show/:id' => 'studies#show_policy_accession', :as => :study_show_policy_accession
  match 'samples/accession/:id' => 'samples#accession'
  match 'samples/accession/show/:id' => 'samples#show_accession'
  match 'samples/destroy/:id' => 'samples#destroy', :as => :destroy_sample
  match 'samples/accession/show/:id' => 'samples#show_accession', :as => :sample_show_accession
  match '/taxon_lookup_by_term/:term' => 'samples#taxon_lookup'
  match '/taxon_lookup_by_id/:id' => 'samples#taxon_lookup'

  resources :studies do

    collection do
      get :study_list
    end

    member do
      get :study_reports
      get :sample_manifests
      get :suppliers
      get :assembly
      put :assembly
      get :new_plate_submission
      post :create_plate_submission
      get :close
      get :open
      get :follow
      get :projects
      get :study_status
      get :collaborators
      get :properties
      get :state
      post :grant_role
      post :remove_role
      get :related_studies
      post :relate_study
      post :unrelate_study
    end

    resources :assets

    resources :sample_registration, :only => [:index,:new,:create], :controller => "studies/sample_registration" do
      collection do
        post :spreadsheet
        # get :new
        get :upload
      end
    end

    resources :samples, :controller => "studies/samples"
    resources :events, :controller => "studies/events"

    resources :requests do
      member do
        post :reset
        get :cancel
      end
    end

    resources :comments, :controller => "studies/comments"

    resources :asset_groups, :controller => "studies/asset_groups" do
      member do
        post :search
        post :add
        get :print
        post :print_labels
        get :printing
      end
    end

    resources :plates, :controller => "studies/plates", :excpet => :destroy do

      collection do
        post :view_wells
        post :asset_group
        get :show_asset_group
      end

      member do
        post :remove_wells
      end

      resources :wells, :expect => [:destroy,:edit]
    end

    resources :workflows, :controller => "studies/workflows" do

      member do
        get :summary
        get :show_summary
      end

      resources :assets do
        collection do
          post :print
        end
      end
    end

    resources :documents, :controller => "studies/documents", :only => [:show,:destroy]

  end

  match 'bulk_submissions' => 'bulk_submissions#new'

  resources :submissions do
    collection do
      get :study_assets
      get :order_fields
      get :project_details
    end
    member do
      post :change_priority
    end
  end

  resources :orders
  resources :documents

  match 'requests/:id/change_decision' => 'requests#filter_change_decision', :as => :filter_change_decision_request, :via => 'get'
  match 'requests/:id/change_decision' => 'requests#change_decision', :as => :change_decision_request, :via => 'put'

  resources :requests do
    resources :comments

    member do
      get :history
      get :copy
      get :cancel
      get :print
    end

    collection do
      get :incomplete_requests_for_family
      get :pending
      get :get_children_requests
      get :mpx_requests_details
    end

  end

  resources :items do
    resource :request
  end

  match 'studies/:study_id/workflows/:id' => 'study_workflows#show', :as => :study_workflow_status

  resources :searches

  namespace :admin do
    resources :custom_texts

    resources :settings do
      collection do
        get :reset
        get :apply
      end
    end

    resources :studies, except:[:destroy]  do
      collection do
        get :index
        post :filter
        post :edit
      end
      member do
        put :managed_update
      end
    end

    resources :projects, except:[:destroy] do
      collection do
        get :index
        post :filter
        post :edit
      end
      member do
        put :managed_update
      end
    end

    resources :plate_purposes
    resources :delayed_jobs
    resources :faculty_sponsors
    resources :programs
    resources :delayed_jobs

    resources :users do

      collection do
        post :filter
      end

      member do
        get :switch
        post :grant_user_role
        post :remove_user_role
      end

    end

    resources :roles do
      resources :users
    end

    resources :robots do
      resources :robot_properties
    end
    resources :bait_libraries


    scope :module => :bait_libraries do
      resources :bait_library_types
      resources :bait_library_suppliers
    end
  end
  match 'admin' => 'admin#index', :as => :admin

  resources :profile, :controller => 'Users' do
    member do
      get :study_reports
      get :projects
    end
  end

  resources :verifications do
    collection do
      get :input
      post :verify
    end
  end

  resources :plate_templates

  match 'implements/print_labels' => 'implements#print_labels'

  resources :implements
  resources :pico_sets do
    collection do
      get :create_from_stock
    end
    member do
      get :analyze
      post :score
      get :normalise_plate
    end
  end

  resources :gels do
    collection do
      post :lookup
      get :find
    end
    # TODO: Remove this route. get gels/:id should be show
    member do
      get :show
    end
  end

  resources :locations
  resources :request_information_types

  match '/logout' => 'sessions#logout', :as => :logout
  match '/login' => 'sessions#login', :as => :login
  match 'pipelines/assets/new/:id' => 'pipelines/assets#new', :via => 'get'

  resources :pipelines, :except => [:delete] do
    collection do
      post :update_priority
    end
    member do
      get :reception
      get :deactivate
      get :activate
      get :show_comments
    end
  end

  resources :lab_searches
  resources :errors
  resources :events

  resources :items do
    collection do
      get :samples_for_autocomplete
    end
  end

  match 'workflows/refresh_sample_list' => 'workflows#refresh_sample_list'

  resources :workflows

  resources :tasks
  resources :asset_audits

  resources :qc_reports, :except => [:delete,:update] do
    collection do
      post :qc_file
    end
  end

  match 'assets/snp_import' => 'assets#snp_import'
  match 'assets/lookup' => 'assets#lookup', :as => :assets_lookup
  match 'assets/receive_barcode' => 'assets#receive_barcode'
  match 'assets/import_from_snp' => 'assets#import_from_snp'
  match 'assets/combine' => 'assets#combine'
  match 'assets/get_plate_layout' => 'assets#get_plate_layout'
  match 'assets/create_plate_layout' => 'assets#create_plate_layout'
  match 'assets/make_plate_from_rack' => 'assets#make_plate_from_rack'
  match 'assets/find_by_barcode' => 'assets#find_by_barcode'
  match 'lab_view' => 'assets#lab_view', :as => :lab_view

  resources :families

  resources :tag_groups, :excpet=>[:destroy] do
    resources :tags, :except => [:destroy, :index, :create, :new, :edit]
  end

  resources :assets do
    collection do
      get :snp_register
      get :reception
      post :print_labels
    end

    member do
      get :parent_assets
      get :child_assets
      get :show_plate
      get :new_request
      post :create_request
      get :summary
      get :close
      get :print
      post :print_items
      get :history
      post :move
    end

    resources :comments, :controller => "assets/comments"
  end

  resources :plates do
    collection do
      post :upload_pico_results
      post :create
      get :to_sample_tubes
      post :create_sample_tubes
    end
  end

  resources :pico_set_results do
    collection do
      post :upload_pico_results
      post :create
    end
  end

  resources :receptions, :only => [:index] do
    collection do
      post :confirm_reception
      get :snp_register
      get :reception
      get :snp_import
      get :receive_snp_barcode
    end
  end

  match 'sequenom/index' => 'sequenom#index', :as => :sequenom_root, :via => 'get'
  match 'sequenom/search' => 'sequenom#search', :as => :sequenom_search, :via => 'post'
  match 'sequenom/:id' => 'sequenom#show', :as => :sequenom_plate, :constraints => 'id(?-mix:\d+)', :via => 'get'
  match 'sequenom/:id' => 'sequenom#update', :as => :sequenom_update, :constraints => 'id(?-mix:\d+)', :via => 'put'
  match 'sequenom/quick' => 'sequenom#quick_update', :as => :sequenom_quick_update, :via => 'post'

  resources :sequenom_qc_plates
  resources :pico_dilutions
  resources :study_reports

  resources :sample_logistics do
    collection do
      get :lab
      get :qc_overview
    end
  end

  scope '0_5', :module => 'api' do

    resources 'asset_audits', :only => [:index, :show]
    resources 'asset_links', :only => [:index, :show]
    resources 'batch_requests', :only => [:index, :show]
    resources 'batches', :only => [:index, :show] do
      member do
        get :children
        get :parents
      end
    end
    resources 'billing_events', :only => [:index, :show]
    resources 'events', :only => [:index, :show]
    resources 'lanes', :only => [:index, :show] do
      member do
        get :children
        get :parents
      end
    end
    resources 'library_tubes', :only => [:index, :show] do
      member do
        get :children
        get :parents
      end

      resources 'lanes', :only => [:index, :show]
      resources 'requests', :only => [:index, :show]
    end
    resources 'multiplexed_library_tubes', :only => [:index, :show] do
      member do
        get :children
        get :parents
      end
    end
    resources 'pulldown_multiplexed_library_tubes', :only => [:index, :show]
    resources 'plate_purposes', :only => [:index, :show]

    resources 'plates', :only => [:index, :show] do
      member do
        get :children
        get :parents
      end
    end

    resources 'sample_tubes', :only => [:index, :show] do
      resources 'library_tubes', :only => [:index, :show]
      resources 'requests', :only => [:index, :show]
      member do
        get :children
        get :parents
      end
    end

    resources 'study_samples', :only => [:index, :show]
    resources 'submissions', :only => [:index, :show] do
      resources 'orders', :only => [:index, :show]
    end
    resources 'orders', :only => [:index, :show]
    resources 'tags', :only => [:index, :show]
    resources 'wells', :only => [:index, :show] do
      member do
        get :children
        get :parents
      end
    end
    resources 'aliquots', :only => [:index, :show]


    resources 'projects', :except => :destroy do
      resources 'studies', :except => :destroy
    end
    resources 'requests', :except => :destroy
    resources 'samples', :except => :destroy do
      member do
        get :children
        get :parents
      end
      resources 'sample_tubes', :only => [:index, :show] do
        member do
          get :children
          get :parents
        end
      end
    end
    resources 'studies', :except => :destroy do
      resources 'samples', :except => :destroy
      resources 'projects', :except => :destroy
    end

  end

  namespace :sdb, as:'' do
    resources :sample_manifests do
      collection do
        post :upload
      end
      member do
        get :export
        get :uploaded_spreadsheet
      end
    end

    resources :suppliers do

      member do
        get :sample_manifests
        get :studies
      end
    end

    match '/' => 'home#index'
  end

  resources :labwhere_receptions, :only => [:index, :create]

  match '/:controller(/:action(/:id))'

end
