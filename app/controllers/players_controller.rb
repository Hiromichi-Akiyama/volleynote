class PlayersController < ApplicationController
  before_action :set_player, only: [:show, :edit, :update, :destroy, :bump_stat]
  
  def index
    @players = current_user.players.order(:number)
  end
  
  def show
    # 選手詳細ページ
  end
  
  def new
    @player = current_user.players.build
  end
  
  def create
    @player = current_user.players.build(player_params)
    
    if @player.save
      redirect_to players_path, notice: '選手が作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @player.update(player_params)
      redirect_to @player, notice: '選手情報が更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @player.destroy
    redirect_to players_path, notice: '選手が削除されました。'
  end
  
  def bump_stat
    stat_key = params[:stat_key]
    delta = params[:delta].to_i
    
    current_value = @player.send(stat_key)
    new_value = [0, current_value + delta].max
    
    @player.update(stat_key => new_value)
    
    render json: { 
      success: true, 
      new_value: new_value,
      player_id: @player.id,
      rates: {
        spike_rate: @player.spike_rate,
        recv_rate: @player.recv_rate,
        serve_effect_rate: @player.serve_effect_rate,
        serve_point_rate: @player.serve_point_rate
      }
    }
  end
  
  private
  
  def set_player
    @player = current_user.players.find(params[:id])
  end
  
  def player_params
    params.require(:player).permit(:name, :number, :position)
  end
end