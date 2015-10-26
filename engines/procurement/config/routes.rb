Procurement::Engine.routes.draw do

  root to: 'application#root'

  resources :budget_periods, only: [:index, :create]

  # resources :requests, only: [:index, :create]

  resources :users, only: [:index, :create] do
    resources :requests, only: [] do
      collection do
        get :resume
      end
    end
  end

  resources :models, only: :index

  resources :suppliers, only: :index

  resources :groups do
    resources :requests, only: [] do
      collection do
        get :resume
      end
    end
    resources :users, only: [] do
      resources :requests, only: [:index, :create]
    end
    resources :request_templates, only: [:index, :create]
  end

  resources :organizations

end
