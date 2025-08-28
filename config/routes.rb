Rails.application.routes.draw do
  devise_for :users
  root 'home#index'
  
  # 認証が必要なページ
  authenticate :user do
    resources :players do
      member do
        patch 'bump_stat'
      end
    end
    
    resources :matches do
      member do
        post 'start'
        patch 'end'
        get 'result'
      end
    end
    
    get 'teams/settings', to: 'teams#settings'
    patch 'teams/settings', to: 'teams#update'
  end
end