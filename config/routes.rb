Befchina::Application.routes.draw do

  resources :test_models

  root :to => "pages#home"

  resource :user_session
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :users
  match 'profile' => 'users#edit', :as => :profile

  match 'imprint' => 'pages#imprint', :as => :imprint
  match 'help' => 'pages#help', :as => :help
  match 'data' => 'pages#data', :as => :data

  resources :datasets do
    member do
      post :clean
    end
  end

  match 'create_dataset' => 'datasets#create', :as => :create_dataset  

  match 'update_dataset_freeformat_associations' => 'datasets#update_dataset_freeformat_associations', :as => :update_dataset_freeformat_associations
  match 'download' => 'datasets#download', :as => :download
  match 'datasets/:id/data' => 'datasets#data', :as => :data_dataset
  match 'datasets/:id/destroy' => 'datasets#destroy', :as => :destroy_dataset
  match 'datasets/:id/approve_predefined' => 'datasets#approve_predefined'

  #Freeformat logic
  match 'datasets/:id/save_dataset_freeformat_tags' => 'datasets#save_dataset_freeformat_tags'
  match 'datasets/update_dataset_freeformat_file' => 'datasets#update_dataset_freeformat_file'
  match 'create_dataset_with_freeformat_file' => 'datasets#create_dataset_with_freeformat_file'
  match 'update_dataset_with_only_freeformat_file' => 'datasets#update_dataset_with_only_freeformat_file'
  match 'save_dataset_freeformat_associations' => 'datasets#save_dataset_freeformat_associations', :as => :save_dataset_freeformat_associations
    
  
  resources :tags

  resources :projects
  resources :datacolumns
  match 'datacolumns/update_datagroup' => 'datacolumns#update_datagroup'
  match 'datacolumns/update_datatype' => 'datacolumns#update_datatype'
  match 'datacolumns/update_metadata' => 'datacolumns#update_metadata'
  match 'datacolumns/update_category' => 'datacolumns#update_category'
  match 'datacolumns/create_category' => 'datacolumns#create_category'
  match 'datacolumns/raw_data_per_header' => 'datacolumns#raw_data_per_header'


  resources :paperproposals
  match 'paperproposals/update_vote/:id' => 'paperproposals#update_vote', :as => :update_vote
  match 'paperproposals/update_state/:id' => 'paperproposals#update_state', :as => :paperproposal_update_state

  namespace :admin do
    resources :datasets, :projects, :users, :datagroups, :tags,
              :datacolumns, :categories, :freeformats, :paperproposals do
      as_routes
    end
  end

  namespace :settings do
    resources :users, :datasets, :datacolumns do
      as_routes
    end
  end

  
  match 'files/freeformats/:id/download' => 'datasets#download_freeformat'
  match 'files/:id/download' => 'datafiles#download'


  resources :carts

  match 'create_cart_context/:dataset_id' => 'carts#create_cart_context', :as => :create_cart_context
  match 'delete_cart_context/:dataset_id' => 'carts#delete_cart_context', :as => :delete_cart_context
  match 'cart' => 'carts#show', :as => 'current_cart'


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
