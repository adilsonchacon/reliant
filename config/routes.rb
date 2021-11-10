Rails.application.routes.draw do
  resources :json_forms do
    resources :values_forms

    member do
      get :generate_structure_for_html_form
    end
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root :to => 'json_forms#index'
end
