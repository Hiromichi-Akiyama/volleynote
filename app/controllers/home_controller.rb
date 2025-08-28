class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  
  def index
    # トップページはログイン不要で表示
  end
end