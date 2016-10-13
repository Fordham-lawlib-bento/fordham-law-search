Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "multi_search#index"
  get "/search" => "multi_search#index", as: 'multi_search'
end
