# frozen_string_literal: true
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  user_is_admin = ->(req) { User.find_by(id: req.session[:user])&.administrator? }
  root to: 'homes#show'
  resource :health, only: [:show]
  resource :home, only: [:show]

  resource :phi_x, only: [:show] do
    scope module: :phi_x do
      resources :stocks
      resources :spiked_buffers
    end
  end

  # Error handling endpoints
  get '/404', to: 'errors#not_found'
  get '/500', to: 'errors#internal_server_error'
  get '/503', to: 'errors#service_unavailable'

  mount Api::RootService.new => '/api/1' unless ENV['DISABLE_V1_API']

  # @todo Update v2 resources exceptions to reflect resources (e.g., `, except: %i[update]` for `lot`),
  #   and more. Include all actions in the except block for immutable resources.
  #   See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
  namespace :api do
    namespace :v2 do
      jsonapi_resources :aliquots
      jsonapi_resources :assets
      jsonapi_resources :asset_audits

      jsonapi_resources :bait_library_layouts, except: %i[update] do
        collection { post :preview }
      end

      jsonapi_resources :barcode_printers
      jsonapi_resources :bulk_transfers, except: %i[update]
      jsonapi_resources :comments, defaults: { permissive: %i[get post] }
      jsonapi_resources :custom_metadatum_collections
      jsonapi_resources :labware, defaults: { permissive: %i[get] }
      jsonapi_resources :lanes
      jsonapi_resources :lot_types
      jsonapi_resources :lots
      jsonapi_resources :orders, except: %i[update]
      jsonapi_resources :pick_lists
      jsonapi_resources :plate_conversions, except: %i[update]
      jsonapi_resources :plate_creations, except: %i[update]
      jsonapi_resources :plate_purposes, except: %i[update]
      jsonapi_resources :plate_templates
      jsonapi_resources :plates, except: %i[update]
      post 'plates/:id/register_stock_for_plate', to: 'plates#register_stock_for_plate'

      jsonapi_resources :poly_metadata
      jsonapi_resources :pooled_plate_creations, except: %i[update]
      jsonapi_resources :pre_capture_pools
      jsonapi_resources :primer_panels
      jsonapi_resources :projects
      jsonapi_resources :purposes
      jsonapi_resources :qc_assays, defaults: { permissive: %i[get post] }
      jsonapi_resources :qc_files, except: %i[update]
      jsonapi_resources :qc_results
      jsonapi_resources :qcables
      jsonapi_resources :qcable_creators, except: %i[update]
      jsonapi_resources :racked_tubes
      jsonapi_resources :receptacles
      jsonapi_resources :request_metadata
      jsonapi_resources :request_types
      jsonapi_resources :requests
      jsonapi_resources :samples
      jsonapi_resources :sample_manifests
      jsonapi_resources :sample_metadata
      jsonapi_resources :specific_tube_creations, except: %i[update]
      jsonapi_resources :specific_tube_rack_creations, except: %i[update]
      jsonapi_resources :state_changes, except: %i[update]
      jsonapi_resources :studies
      jsonapi_resources :submission_pools
      jsonapi_resources :submission_templates
      jsonapi_resources :submissions, except: %i[update]
      jsonapi_resources :tag_group_adapter_types
      jsonapi_resources :tag_groups, defaults: { permissive: %i[get] }
      jsonapi_resources :tag_sets, only: %i[index show]
      jsonapi_resources :tag_layout_templates
      jsonapi_resources :tag_layouts, except: %i[update]
      jsonapi_resources :tags
      jsonapi_resources :transfer_request_collections, except: %i[update]
      jsonapi_resources :transfer_requests
      jsonapi_resources :transfer_templates
      jsonapi_resources :transfers, except: %i[update]
      jsonapi_resources :tube_from_tube_creations, except: %i[update]
      jsonapi_resources :tube_from_plate_creations, except: %i[update]
      jsonapi_resources :tube_purposes
      jsonapi_resources :tube_rack_purposes
      jsonapi_resources :tube_rack_statuses
      jsonapi_resources :tube_racks
      jsonapi_resources :tubes
      jsonapi_resources :users
      jsonapi_resources :volume_updates
      jsonapi_resources :wells
      jsonapi_resources :work_completions, except: %i[update]
      jsonapi_resources :work_orders

      namespace :heron do
        resources :tube_rack_statuses, only: [:create]
        resources :tube_racks, only: [:create]
        resources :plates, only: [:create]
      end

      namespace :bioscan do
        resources :export_pool_xp_to_traction, only: [:create]
      end
    end
  end

  resources :samples do
    resources :assets, except: :destroy
    resources :comments, controller: 'samples/comments'
    resources :studies

    member do
      get :history
      put :add_to_study
      get :release
      get :remove_from_study
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

  match '/login' => 'sessions#login', :as => :login, :via => %i[get post]
  match '/logout' => 'sessions#logout', :as => :logout, :via => %i[get post]

  resources :plate_summaries, only: %i[index show] do
    collection { get :search }
  end

  resources :tube_rack_summaries, only: :show
  resources :tube_rack_statuses, only: :index

  resources :reference_genomes
  resources :barcode_printers

  resources :robot_verifications do
    collection do
      post :submission
      get :submission
      post :download
      get :finish
    end
  end

  resources :stock_stampers, only: %i[new create] do
    collection do
      post :generate_tecan_file
      post :print_label
    end
  end

  scope 'npg_actions', module: 'npg_actions' do
    resources :assets, only: [] do
      post :pass_qc_state, action: :pass, format: :xml
      post :fail_qc_state, action: :fail, format: :xml
    end
  end

  resources :batches do
    resources :requests, controller: 'batches/requests'
    resources :comments, controller: 'batches/comments'

    resources :robots do
      resource :driver_file, only: :show
    end

    member do
      get :print_labels
      get :print_plate_labels
      get :filtered
      post :swap
      post :fail_items
      post :reset_batch
      get :download_spreadsheet
      get :fail
      get :print
      get :verify
      post :verify_tube_layout
      get :previous_qc_state
      get :released
      get :sample_prep_worksheet
      get :new_stock_assets
      get :generate_sample_sheet
    end

    collection do
      post :print_barcodes
      post :print_plate_barcodes
      post :sort
      get 'find_batch_by_barcode/:id', action: 'find_batch_by_barcode'
    end
  end
  resources :uuids, only: [:show]

  get 'pipelines/release/:id' => 'pipelines#release', :as => :release_batch
  get 'pipelines/finish/:id' => 'pipelines#finish', :as => :finish_batch

  resources :events
  resources :sources

  get '/taxon_lookup_by_term/:term' => 'samples#taxon_lookup'
  get '/taxon_lookup_by_id/:id' => 'samples#taxon_lookup'

  post '/studies/:study_id/information/summary_detailed/:id' => 'studies/information#summary_detailed'

  get 'studies/accession/:id' => 'studies#accession'
  get 'studies/policy_accession/:id' => 'studies#policy_accession'
  get 'studies/dac_accession/:id' => 'studies#dac_accession'

  get 'studies/accession/show/:id' => 'studies#show_accession', :as => :study_show_accession
  get 'studies/accession/dac/show/:id' => 'studies#show_dac_accession', :as => :study_show_dac_accession
  get 'studies/accession/policy/show/:id' => 'studies#show_policy_accession', :as => :study_show_policy_accession

  get 'samples/accession/:id' => 'samples#accession'
  get 'samples/accession/show/:id' => 'samples#show_accession', :as => :sample_show_accession

  resources :studies do
    collection { get :study_list }

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
      get :accession_all_samples
    end

    resources :assets, except: [:destroy]

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
      collection { get :printing }
    end

    resources :plates, controller: 'studies/plates', except: :destroy do
      collection do
        post :view_wells
        post :asset_group
        get :show_asset_group
      end

      member { post :remove_wells }

      resources :wells, expect: %i[destroy edit]
    end

    resource :information, controller: 'studies/information' do
      member do
        get :summary
        get :show_summary
      end

      resources :assets # Legacy path, redirects to receptacles
      resources :receptacles do
        collection { post :print }
      end
    end

    resources :documents, controller: 'studies/documents', only: %i[show destroy]
  end

  resources :bulk_submissions, only: %i[index new create]
  resources :bulk_submission_excel_downloads, only: %i[create new], controller: 'bulk_submission_excel/downloads'

  resources :submissions do
    collection do
      get :study_assets
      get :order_fields
      get :project_details
      get :study
    end
    member do
      post :change_priority
      post :cancel
    end
  end

  resources :orders
  resources :documents

  get 'requests/:id/change_decision' => 'requests#filter_change_decision', :as => :filter_change_decision_request
  put 'requests/:id/change_decision' => 'requests#change_decision', :as => :change_decision_request

  resources :requests do
    resources :comments, controller: 'requests/comments'
    resources :poly_metadata, controller: 'requests/poly_metadata'

    member do
      get :history
      get :copy
      get :cancel
      get :print
      delete 'reset_qc_information/:event_id', action: :reset_qc_information
    end
  end

  resources :searches

  namespace :admin do
    resources :abilities, only: :index
    resources :custom_texts

    resources :primer_panels, except: :destroy

    resources :studies, except: [:destroy] do
      collection do
        get :index
        post :filter
        post :edit
      end
      member { put :managed_update }
    end

    resources :projects, except: [:destroy] do
      collection do
        get :index
        post :filter
        post :edit
      end
      member { put :managed_update }
    end

    resources :plate_purposes
    resources :delayed_jobs
    resources :faculty_sponsors
    resources :programs
    resources :delayed_jobs

    resources :users do
      collection { post :filter }

      member do
        get :switch
        post :grant_user_role
        post :remove_user_role
      end
    end

    resources :roles, only: %i[index show new create] do
      resources :users, controller: 'roles/users'
    end

    resources :robots do
      resources :robot_properties do
        member { get :print_labels }
      end
    end
    resources :bait_libraries

    scope module: :bait_libraries do
      resources :bait_library_types
      resources :bait_library_suppliers
    end
  end

  get 'admin' => 'admin#index', :as => :admin
  get 'admin/filter'

  resources :profile, controller: 'users' do
    member do
      get :study_reports
      get :projects
      post :print_swipecard
    end
  end

  resources :plate_templates

  resources :gels do
    collection do
      post :lookup
      get :find
    end

    # TODO: Remove this route. get gels/:id should be show
    member { get :show }
  end

  resources :pipelines, except: [:delete] do
    collection { post :update_priority }
    member do
      get :reception
      get :deactivate
      get :activate
      get :show_comments
      get :batches
      get :summary
    end

    resources :batches, only: [:index] do
      collection do
        get :pending
        get :started
        get :released
        get :completed
        get :failed
        get :discarded
      end
    end
  end

  resources :lab_searches
  resources :events

  get 'advanced_search' => 'advanced_search#index'
  post 'advanced_search/search' => 'advanced_search#search'

  resources :workflows, only: [] do
    member do
      # Yes, this is every bit as horrible as it looks.
      # HTTP Verbs! Gotta catch em all!
      # workflows/stage controller need substantial
      # reworking.
      patch 'stage/:id' => 'workflows#stage'
      get 'stage/:id' => 'workflows#stage'
      post 'stage/:id' => 'workflows#stage'
    end
    collection { get :generate_manifest }
  end

  resources :asset_audits

  resources :qc_reports, except: %i[delete update] do
    collection { post :qc_file }
  end

  get 'assets/lookup' => 'assets#lookup', :as => :assets_lookup

  get 'assets/find_by_barcode', to: redirect('labware/find_by_barcode')
  get 'labware/find_by_barcode' => 'labware#find_by_barcode'

  get 'lab_view' => 'labware#lab_view', :as => :lab_view
  post 'labware/lab_view'

  resources :tag_groups, except: [:destroy] do
    resources :tags, except: %i[destroy index create new edit]
  end

  resources :tag_sets, only: %i[index new create show]

  resources :tag_layout_templates, only: %i[index new create show]

  resources :assets, except: %i[create new] do
    collection do
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
      get :print
      get :history
      post :move
      post :print_assets
    end

    resources :qc_files
  end

  resources :labware, except: %i[create new] do
    collection do
      get :reception
      post :print_labels
    end

    member do
      get :parent_assets
      get :child_assets
      get :show_plate
      get :summary
      get :close
      get :print
      get :history
      get :retention_instruction
      post :move
      post :print_assets
    end

    resources :qc_files
    resources :comments, controller: 'labware/comments'
  end

  resources :receptacles, except: %i[create new] do
    collection do
      get :reception
      post :print_labels
    end

    resources :tag_substitutions, only: :new

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
      post :print_assets
    end

    resources :comments, controller: 'receptacles/comments'
  end

  # Merge conflict tip: Specifying controller: :assets here is to
  # handle the current lack of the receptacles controller. If you're seeing
  # the more fully specced route alongside this, then it should be enough to
  # add resource :parent, only: :show to the more fully specced route
  resources :receptacles, only: [:show], controller: :assets do
    resource :parent, only: :show
  end

  resources :plates do
    collection do
      post :create
      get :to_sample_tubes
      post :create_sample_tubes
      get :from_tubes, controller: 'plates_from_tubes', action: 'new'
      post :from_tubes, controller: 'plates_from_tubes', action: 'create'
    end

    member { get :fluidigm_file }
  end

  resources :sequenom_qc_plates, only: :index
  resources :study_reports

  resources :tag_substitutions, only: :create

  resources :sample_logistics do
    collection { get :lab }
  end

  scope '/sdb', module: 'sdb' do
    resources :sample_manifests do
      member do
        get :export
        get :uploaded_spreadsheet
        post :print_labels
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

  resources :labwhere_receptions, only: %i[index create]

  resources :report_fails, only: %i[index create]

  resources :qc_files, only: %i[show create]

  resources :user_queries, only: %i[new create]

  resources :poolings, only: %i[new create]

  post 'get_your_qc_completed_tubes_here' => 'get_your_qc_completed_tubes_here#create',
       :as => :get_your_qc_completed_tubes_here
  resources :sample_manifest_upload_with_tag_sequences, only: %i[new create]

  resources :uat_actions

  resources :location_reports, only: %i[index show create]

  # this is for test only test/functional/authentication_controller_test.rb
  # to be removed?
  get 'authentication/open'
  get 'authentication/restricted'

  resources :messengers, only: :show

  # We removed workflows, which broke study links. Some customers may have their own studies bookmarked
  get 'studies/:study_id/workflows/:id', to: redirect('studies/%{study_id}/information')

  resources :quad_stamp, only: %i[new create]
  resources :pick_lists, only: %i[index show]
  resource :plate_picks, only: [:show] do
    member do
      get 'plates/:barcode', to: 'plate_picks#plates'
      get 'batches/:id', to: 'plate_picks#batches'
    end
  end

  mount Flipper::UI.app => '/flipper', :constraints => user_is_admin
end
