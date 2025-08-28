class MatchesController < ApplicationController
  before_action :set_match, only: [:show, :start, :end_match, :result, :add_player, :remove_player, :substitute_player, :record_stat, :move_to_bench, :move_to_court]  
  def index
    @players = current_user.players.order(:number)
    @current_match = current_user.matches.preparing.first
    
    if @current_match.nil?
      @current_match = current_user.matches.create!(status: :preparing)
    end
    
    redirect_to @current_match
  end
  
  def show
    @players = current_user.players.order(:number)
    @match_players = @match.players.includes(:user).order(:number)
    @available_players = current_user.players.where.not(id: @match.players.ids).order(:number)
  end
  
  def new
    @match = current_user.matches.build
    @players = current_user.players.order(:number)
  end
  
  def create
    @match = current_user.matches.build(status: :preparing)
    
    if @match.save
      redirect_to @match, notice: '新しい試合が作成されました。'
    else
      @players = current_user.players.order(:number)
      render :new, status: :unprocessable_entity
    end
  end
  
  def start
    starting_player_ids = (params[:starting_players] || []).map(&:to_i)
    bench_player_ids = (params[:bench_players] || []).map(&:to_i)
    
    if starting_player_ids.empty?
      render json: { success: false, message: '少なくとも1名のスターティングメンバーを選択してください。' }
      return
    end
    
    ActiveRecord::Base.transaction do
      @match.update!(status: :active, started_at: Time.current)
      
      starting_player_ids.each do |player_id|
        @match.match_players.create!(
          player_id: player_id,
          role: :starting,
          court_status: :on_court
        )
      end
      
      bench_player_ids.each do |player_id|
        @match.match_players.create!(
          player_id: player_id,
          role: :bench,
          court_status: :on_bench
        )
      end
    end
    
    render json: { 
      success: true, 
      message: "試合が開始されました！先発#{starting_player_ids.length}名、ベンチ#{bench_player_ids.length}名",
      redirect_url: match_path(@match)
    }
  rescue => e
    render json: { success: false, message: e.message }
  end
  
  def end_match
    @match.update!(status: :completed, ended_at: Time.current)
    redirect_to result_match_path(@match), notice: '試合が終了しました。'
  end
  
  def add_player
    player_id = params[:player_id].to_i
    court_status = params[:court_status] || 'on_bench'
    
    player = current_user.players.find(player_id)
    
    if @match.match_players.exists?(player: player)
      render json: { success: false, message: 'この選手は既に試合に参加しています。' }
      return
    end
    
    @match.match_players.create!(
      player: player,
      role: :bench,
      court_status: court_status
    )
    
    render json: { 
      success: true, 
      message: "#{player.name}(##{player.number})が追加されました。",
      player: render_player_data(player)
    }
  end
  
  # ベンチに移動（試合から除外しない）
  def move_to_bench
    player_id = params[:player_id].to_i
    match_player = @match.match_players.find_by(player_id: player_id)
    
    if match_player&.on_court?
      match_player.update!(court_status: :on_bench)
      
      render json: { 
        success: true, 
        message: "#{match_player.player.name}(##{match_player.player.number})をベンチに移動しました。"
      }
    else
      render json: { success: false, message: '選手が見つからないか、既にベンチにいます。' }
    end
  end
  
  # ベンチからコートへ移動
  def move_to_court
    player_id = params[:player_id].to_i
    match_player = @match.match_players.find_by(player_id: player_id)
    
    if match_player&.on_bench?
      # コートの人数制限チェック
      if @match.match_players.on_court.count >= 6
        render json: { success: false, message: 'コートには最大6名まで配置できます。' }
        return
      end
      
      match_player.update!(court_status: :on_court)
      
      render json: { 
        success: true, 
        message: "#{match_player.player.name}(##{match_player.player.number})をコートに投入しました。"
      }
    else
      render json: { success: false, message: '選手が見つからないか、既にコートにいます。' }
    end
  end
  
  # 試合から完全に除外
  def remove_player
    player_id = params[:player_id].to_i
    match_player = @match.match_players.find_by(player_id: player_id)
    
    if match_player
      player_name = match_player.player.name
      player_number = match_player.player.number
      match_player.destroy
      
      render json: { 
        success: true, 
        message: "#{player_name}(##{player_number})を試合から除外しました。"
      }
    else
      render json: { success: false, message: '選手が見つかりません。' }
    end
  end
  
  def substitute_player
    out_player_id = params[:out_player_id].to_i
    in_player_id = params[:in_player_id].to_i
    
    out_match_player = @match.match_players.find_by(player_id: out_player_id)
    in_match_player = @match.match_players.find_by(player_id: in_player_id)
    
    if out_match_player&.on_court? && in_match_player&.on_bench?
      ActiveRecord::Base.transaction do
        out_match_player.update!(court_status: :on_bench)
        in_match_player.update!(court_status: :on_court)
      end
      
      render json: { 
        success: true, 
        message: "交代完了：#{out_match_player.player.name}(##{out_match_player.player.number}) ↔ #{in_match_player.player.name}(##{in_match_player.player.number})"
      }
    else
      render json: { success: false, message: '交代できません。選手の状態を確認してください。' }
    end
  end
  
  def record_stat
    player_id = params[:player_id].to_i
    stat_type = params[:stat_type]
    delta = params[:delta].to_i
    
    player = @match.players.find(player_id)
    
    if delta > 0
      delta.times do
        @match.match_events.create!(
          player: player,
          event_type: stat_type,
          value: 1
        )
      end
    elsif delta < 0
      events_to_remove = @match.match_events
                                .where(player: player, event_type: stat_type)
                                .order(created_at: :desc)
                                .limit(-delta)
      events_to_remove.destroy_all
    end
    
    current_stats = @match.match_stats_for_player(player)
    
    render json: { 
      success: true,
      player_id: player.id,
      stats: current_stats,
      rates: calculate_rates(current_stats)
    }
  end
  
  def result
    @team_stats = @match.team_stats
    @mvp = @match.mvp_player
    @position_awards = @match.position_awards
    @match_players_data = generate_match_players_data
  end
  
  def print_result
    @team_stats = @match.team_stats
    @mvp = @match.mvp_player
    @position_awards = @match.position_awards
    @match_players_data = generate_match_players_data
    
    render 'print_result', layout: 'print'
  end
  
  private
  
  def set_match
    @match = current_user.matches.find(params[:id])
  end
  
  def render_player_data(player)
    {
      id: player.id,
      name: player.name,
      number: player.number,
      position: player.position
    }
  end
  
  def calculate_rates(stats)
    {
      spike_rate: calculate_rate(stats[:spike_kills], stats[:spike_attempts]),
      recv_rate: calculate_rate(stats[:recv_successes], stats[:recv_attempts]),
      serve_effect_rate: calculate_rate(stats[:serve_effects], stats[:serve_attempts]),
      serve_point_rate: calculate_rate(stats[:serve_points], stats[:serve_attempts])
    }
  end
  
  def calculate_rate(numerator, denominator)
    return 0.0 if denominator.zero?
    (numerator.to_f / denominator * 100).round(1)
  end
  
  def generate_match_players_data
    @match.players.map do |player|
      stats = @match.match_stats_for_player(player)
      rates = calculate_rates(stats)
      
      {
        player: player,
        stats: stats,
        rates: rates,
        total_score: @match.send(:calculate_player_score, stats)
      }
    end.sort_by { |data| -data[:total_score] }
  end
end