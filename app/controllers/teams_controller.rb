class TeamsController < ApplicationController
  def settings
    @user = current_user
  end
  
  def update
    if current_user.update(user_params)
      redirect_to teams_settings_path, notice: 'チーム情報が更新されました。'
    else
      render :settings, status: :unprocessable_entity
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:team_name, :coach_name)
  end
end