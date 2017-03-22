# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

Sequencescape::Application.routes.draw do
  root to: 'homes#show'
  resource :home, only: [:show]

  mount Api::RootService.new => '/api/1'

  resources :samples do
    resources :assets, except: :destroy
    resources :comments, controller: 'samples/comments'
    resources :studies

    member do
      get :history
      put :add_to_study
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

  match '/login' => 'sessions#login', :as => :login, :via => [:get, :post]
  match '/logout' => 'sessions#logout', :as => :logout, :via => [:get, :post]

  resources :plate_summaries, only: [:index, :show] do
    collection do
      get :search
    end
  end

  resources :reference_genomes
  resources :barcode_printers

  resources :robot_verifications do
    collection do
      post :submission
      get :submission
      post :download
    end
  end

  scope 'npg_actions', module: 'npg_actions' do
    resources :assets, only: [] do
      post :pass_qc_state, action: :pass, format: :xml
      post :fail_qc_state, action: :fail, format: :xml
    end
  end

  resources :items

  resources :batches do
    resources :requests, controller: 'batches/requests'
    resources :comments, controller: 'batches/comments'
    resources :stock_assets, only: [:new, :create]

    member do
      get :print_labels
      get :print_stock_labels
      get :print_plate_labels
      get :filtered
      post :swap
      get :gwl_file
      post :fail_items
      post :create_training_batch
      post :reset_batch
    end

    collection do
      post :print_barcodes
      post :print_plate_barcodes
    end
  end
  resources :uuids, only: [:show]

  match 'pipelines/release/:id' => 'pipelines#release', :as => :release_batch, :via => :post
  match 'pipelines/finish/:id' => 'pipelines#finish', :as => :finish_batch, :via => :post

  resources :events
  resources :sources

  match '/taxon_lookup_by_term/:term' => 'samples#taxon_lookup', :via => :get
  match '/taxon_lookup_by_id/:id' => 'samples#taxon_lookup', :via => :get

  match '/studies/:study_id/workflows/:workflow_id/summary_detailed/:id' => 'studies/workflows#summary_detailed', :via => :post

  match 'studies/accession/:id' => 'studies#accession', :via => :get
  match 'studies/policy_accession/:id' => 'studies#policy_accession', :via => :get
  match 'studies/dac_accession/:id' => 'studies#dac_accession', :via => :get

  match 'studies/accession/show/:id' => 'studies#show_accession', :as => :study_show_accession, :via => :get
  match 'studies/accession/dac/show/:id' => 'studies#show_dac_accession', :as => :study_show_dac_accession, :via => :get
  match 'studies/accession/policy/show/:id' => 'studies#show_policy_accession', :as => :study_show_policy_accession, :via => :get

  match 'samples/accession/:id' => 'samples#accession', :via => :get
  match 'samples/accession/show/:id' => 'samples#show_accession', :via => :get
  match 'samples/accession/show/:id' => 'samples#show_accession', :as => :sample_show_accession, :via => :get

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
      post :close
      post :open
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

    resources :assets, except: :destroy

    resources :sample_registration, only: [:index, :new, :create], controller: 'studies/sample_registration' do
      collection do
        post :spreadsheet
        # get :new
        get :upload
      end
    end

    resources :samples, controller: 'studies/samples'
    resources :events, controller: 'studies/events'

    resources :requests do
      member do
        post :reset
        get :cancel
      end
    end

    resources :comments, controller: 'studies/comments'

    resources :asset_groups, controller: 'studies/asset_groups' do
      member do
        post :search
        post :add
        get :print
        post :print_labels
      end
      collection do
        get :printing
      end
    end

    resources :plates, controller: 'studies/plates', except: :destroy do
      collection do
        post :view_wells
        post :asset_group
        get :show_asset_group
      end

      member do
        post :remove_wells
      end

      resources :wells, expect: [:destroy, :edit]
    end

    resources :workflows, controller: 'studies/workflows' do
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

    resources :documents, controller: 'studies/documents', only: [:show, :destroy]
  end

  resources :bulk_submissions, only: [:index, :new, :create]

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
    resources :comments, controller: 'requests/comments'

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
    end
  end

  resources :items do
    resource :request
  end

  get 'studies/:study_id/workflows/:id' => 'study_workflows#show', :as => :study_workflow_status

  resources :searches

  namespace :admin do
    resources :custom_texts

    resources :settings do
      collection do
        get :reset
        get :apply
      end
    end

    resources :studies, except: [:destroy] do
      collection do
        get :index
        post :filter
        post :edit
      end
      member do
        put :managed_update
      end
    end

    resources :projects, except: [:destroy] do
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

    resources :roles, only: [:index, :show, :new, :create] do
      resources :users, only: :index
    end

    # scope :module => :roles do
    #   resources :users, only: :index
    # end

    resources :robots do
      resources :robot_properties do
        member do
          get :print_labels
        end
      end
    end
    resources :bait_libraries

    scope module: :bait_libraries do
      resources :bait_library_types
      resources :bait_library_suppliers
    end
  end

  get 'admin' => 'admin#index', :as => :admin

  resources :profile, controller: 'users' do
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

  get 'implements/print_labels' => 'implements#print_labels'

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

  match 'pipelines/assets/new/:id' => 'pipelines/assets#new', :via => 'get'

  resources :pipelines, except: [:delete] do
    collection do
      post :update_priority
    end
    member do
      get :reception
      get :deactivate
      get :activate
      get :show_comments
    end

    resources :batches, only: [:index] do
      collection do
        get :pending
        get :started
        get :released
        get :completed
        get :failed
      end
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

  resources :workflows, except: :delete do
    member do
      # Yes, this is every bit as horrible as it looks.
      # HTTP Verbs! Gotta catch em all!
      # workflows/stage controller need substantial
      # reworking.
      patch 'stage/:id' => 'workflows#stage'
      get   'stage/:id' => 'workflows#stage'
      post 'stage/:id' => 'workflows#stage'
    end
  end

  resources :tasks
  resources :asset_audits

  resources :qc_reports, except: [:delete, :update] do
    collection do
      post :qc_file
    end
  end

  get 'assets/snp_import' => 'assets#snp_import'
  get 'assets/lookup' => 'assets#lookup', :as => :assets_lookup
  get 'assets/receive_barcode' => 'assets#receive_barcode'
  get 'assets/import_from_snp' => 'assets#import_from_snp'
  get 'assets/find_by_barcode' => 'assets#find_by_barcode'
  get 'lab_view' => 'assets#lab_view', :as => :lab_view

  resources :families

  resources :tag_groups, excpet: [:destroy] do
    resources :tags, except: [:destroy, :index, :create, :new, :edit]
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

    resources :comments, controller: 'assets/comments'
  end

  resources :plates do
    collection do
      post :upload_pico_results
      post :create
      get :to_sample_tubes
      post :create_sample_tubes
    end
  end

  resources :pico_set_results, only: :create

  resources :receptions, only: [:index] do
    collection do
      post :confirm_reception
      get :snp_register
      get :reception
      get :snp_import
      get :receive_snp_barcode
      post :receive_barcode
    end
  end

  match 'sequenom/index' => 'sequenom#index', :as => :sequenom_root, :via => 'get'
  match 'sequenom/search' => 'sequenom#search', :as => :sequenom_search, :via => 'post'
  match 'sequenom/:id' => 'sequenom#show', :as => :sequenom_plate, :via => 'get'
  match 'sequenom/:id' => 'sequenom#update', :as => :sequenom_update, :via => 'put'
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

  scope '0_5', module: 'api' do
    resources 'asset_audits', only: [:index, :show]
    resources 'asset_links', only: [:index, :show]
    resources 'batch_requests', only: [:index, :show]
    resources 'batches', only: [:index, :show] do
      member do
        get :children
        get :parents
      end
    end
    resources 'billing_events', only: [:index, :show]
    resources 'events', only: [:index, :show]
    resources 'lanes', only: [:index, :show] do
      member do
        get :children
        get :parents
      end
    end
    resources 'library_tubes', only: [:index, :show] do
      member do
        get :children
        get :parents
      end

      resources 'lanes', only: [:index, :show]
      resources 'requests', only: [:index, :show]
    end
    resources 'multiplexed_library_tubes', only: [:index, :show] do
      member do
        get :children
        get :parents
      end
    end
    resources 'pulldown_multiplexed_library_tubes', only: [:index, :show]
    resources 'plate_purposes', only: [:index, :show]

    resources 'plates', only: [:index, :show] do
      member do
        get :children
        get :parents
      end
    end

    resources 'sample_tubes', only: [:index, :show] do
      resources 'library_tubes', only: [:index, :show]
      resources 'requests', only: [:index, :show]
      member do
        get :children
        get :parents
      end
    end

    resources 'study_samples', only: [:index, :show]
    resources 'submissions', only: [:index, :show] do
      resources 'orders', only: [:index, :show]
    end
    resources 'orders', only: [:index, :show]
    resources 'tags', only: [:index, :show]
    resources 'wells', only: [:index, :show] do
      member do
        get :children
        get :parents
      end
    end
    resources 'aliquots', only: [:index, :show]

    resources 'projects', except: :destroy do
      resources 'studies', except: :destroy
    end
    resources 'requests', except: :destroy
    resources 'samples', except: :destroy do
      member do
        get :children
        get :parents
      end
      resources 'sample_tubes', only: [:index, :show] do
        member do
          get :children
          get :parents
        end
      end
    end
    resources 'studies', except: :destroy do
      resources 'samples', except: :destroy
      resources 'projects', except: :destroy
    end
  end

  scope '/sdb', module: 'sdb' do
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

    get '/' => 'home#index'
  end

  resources :labwhere_receptions, only: [:index, :create]

  resources :qc_files, only: [:show]

  resources :user_queries, only: [:new, :create]

  post 'get_your_qc_completed_tubes_here' => 'get_your_qc_completed_tubes_here#create', as: :get_your_qc_completed_tubes_here

  # These endpoints should be defined explicitly
  get '/:controller(/:action(/:id))'
  post '/:controller(/:action(/:id))'
end
