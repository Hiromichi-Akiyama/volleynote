Rails.application.routes.draw do
  devise_for :users
  root 'home#index'
  
  authenticate :user do
    resources :players do
      member do
        patch 'bump_stat'
      end
    end
    
    resources :matches do
      member do
        post 'start'
        get 'end_match'
        get 'result'
        get 'print_result'
        post 'add_player'
        patch 'move_to_bench'
        patch 'move_to_court'  # 新しいルート
        delete 'remove_player'
        patch 'substitute_player'
        patch 'record_stat'
      end
    end
    
    get 'teams/settings', to: 'teams#settings'
    patch 'teams/settings', to: 'teams#update'
  end
end