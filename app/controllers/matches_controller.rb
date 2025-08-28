class MatchesController < ApplicationController
  before_action :set_match, only: [:show, :start, :end, :result]
  
  def index
    @players = current_user.players.order(:number)
    @current_match = current_user.matches.active.first
    
    if @current_match
      redirect_to @current_match
    end
  end
  
  def show
    @match_players = @match.players.includes(:user)
  end
  
  def new
    @match = current_user.matches.build
  end
  
  def create
    @match = current_user.matches.build(match_params)
    @match.status = :preparing
    
    if @match.save
      redirect_to @match, notice: '新しい試合が作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def start
    @match.update(status: :active, started_at: Time.current)
    
    # 選択された選手を試合に追加
    starting_player_ids = params[:starting_players] || []
    bench_player_ids = params[:bench_players] || []
    
    starting_player_ids.each do |player_id|
      @match.match_players.find_or_create_by(player_id: player_id) do |mp|
        mp.role = :starting
        mp.court_status = :on_court
      end
    end
    
    bench_player_ids.each do |player_id|
      @match.match_players.find_or_create_by(player_id: player_id) do |mp|
        mp.role = :bench
        mp.court_status = :on_bench
      end
    end
    
    render json: { success: true, message: '試合が開始されました。' }
  end
  
  def end
    @match.update(status: :completed, ended_at: Time.current)
    redirect_to match_result_path(@match), notice: '試合が終了しました。'
  end
  
  def result
    @match_players = @match.players.includes(:user)
  end
  
  private
  
  def set_match
    @match = current_user.matches.find(params[:id])
  end
  
  def match_params
    params.require(:match).permit(:opponent_team)
  end
end