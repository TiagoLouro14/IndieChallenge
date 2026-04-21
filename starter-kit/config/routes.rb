Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'welcome#index'

  namespace :api do
    namespace :v1 do
      resources :locations, only: %i[index show]
      resources :pois, only: %i[index show] do
        collection do
          get :nearest
        end
      end
      get 'trips/plan', to: 'trips#plan'
    end
  end

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
end
