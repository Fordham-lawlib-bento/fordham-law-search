Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "multi_search#index"
  get "/search" => "multi_search#index", as: 'multi_search'
  get "/search-embed" => "multi_search#search_form_embed", as: 'search_embed'

  # constrained to just the engine(s) we want to show our own single-search
  # results for.
  get "/search/:engine" => "single_search#index", engine: /website/, as: 'single_search'

  # ajax results loader
  BentoSearch::Routes.new(self).draw
end
