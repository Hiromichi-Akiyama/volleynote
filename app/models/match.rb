class Match < ApplicationRecord
  belongs_to :user
  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players
  has_many :match_events, dependent: :destroy
  
  validates :status, presence: true
  
  enum status: { preparing: 0, active: 1, completed: 2 }
  
  scope :recent, -> { order(created_at: :desc) }
  
  def starting_players
    match_players.starting.includes(:player).map(&:player)
  end
  
  def bench_players
    match_players.bench.includes(:player).map(&:player)
  end
  
  def court_players
    match_players.on_court.includes(:player).map(&:player)
  end
  
  def match_stats_for_player(player)
    events = match_events.where(player: player)
    
    {
      spike_attempts: events.where(event_type: 'spike_attempt').sum(:value),
      spike_kills: events.where(event_type: 'spike_kill').sum(:value),
      recv_attempts: events.where(event_type: 'recv_attempt').sum(:value),
      recv_successes: events.where(event_type: 'recv_success').sum(:value),
      serve_attempts: events.where(event_type: 'serve_attempt').sum(:value),
      serve_effects: events.where(event_type: 'serve_effect').sum(:value),
      serve_points: events.where(event_type: 'serve_point').sum(:value)
    }
  end
  
  def team_stats
    all_players = players.includes(:match_events)
    
    total_stats = {
      spike_attempts: 0, spike_kills: 0,
      recv_attempts: 0, recv_successes: 0,
      serve_attempts: 0, serve_effects: 0, serve_points: 0
    }
    
    all_players.each do |player|
      player_stats = match_stats_for_player(player)
      total_stats.each { |key, _| total_stats[key] += player_stats[key] }
    end
    
    {
      spike_rate: calculate_rate(total_stats[:spike_kills], total_stats[:spike_attempts]),
      recv_rate: calculate_rate(total_stats[:recv_successes], total_stats[:recv_attempts]),
      serve_effect_rate: calculate_rate(total_stats[:serve_effects], total_stats[:serve_attempts])
    }
  end
  
  def mvp_player
    player_scores = players.map do |player|
      stats = match_stats_for_player(player)
      score = calculate_player_score(stats)
      { player: player, stats: stats, score: score }
    end
    
    player_scores.max_by { |p| p[:score] }
  end
  
  def position_awards
    awards = {}
    
    players.includes(:match_events).group_by(&:position).each do |position, position_players|
      best_player = position_players.max_by do |player|
        stats = match_stats_for_player(player)
        calculate_player_score(stats)
      end
      
      if best_player
        awards[position] = {
          player: best_player,
          stats: match_stats_for_player(best_player),
          score: calculate_player_score(match_stats_for_player(best_player))
        }
      end
    end
    
    awards
  end
  
  private
  
  def calculate_rate(numerator, denominator)
    return 0.0 if denominator.zero?
    (numerator.to_f / denominator * 100).round(1)
  end
  
  def calculate_player_score(stats)
    (stats[:spike_kills] * 3) + 
    (stats[:recv_successes] * 2) + 
    (stats[:serve_effects] * 2) + 
    (stats[:serve_points] * 4) +
    (calculate_rate(stats[:spike_kills], stats[:spike_attempts]) * stats[:spike_attempts] * 0.1) +
    (calculate_rate(stats[:recv_successes], stats[:recv_attempts]) * stats[:recv_attempts] * 0.05) +
    (calculate_rate(stats[:serve_effects], stats[:serve_attempts]) * stats[:serve_attempts] * 0.05)
  end
end