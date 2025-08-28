class Player < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :number, presence: true, uniqueness: { scope: :user_id }
  validates :position, presence: true
  
  def spike_rate
    return 0.0 if spike_attempts.zero?
    (spike_kills.to_f / spike_attempts * 100).round(1)
  end
  
  def recv_rate
    return 0.0 if recv_attempts.zero?
    (recv_successes.to_f / recv_attempts * 100).round(1)
  end
  
  def serve_effect_rate
    return 0.0 if serve_attempts.zero?
    (serve_effects.to_f / serve_attempts * 100).round(1)
  end
  
  def serve_point_rate
    return 0.0 if serve_attempts.zero?
    (serve_points.to_f / serve_attempts * 100).round(1)
  end
  
  def total_score
    (spike_kills * 3) + (recv_successes * 2) + (serve_effects * 2) + (serve_points * 4) +
    (spike_rate * spike_attempts * 0.1) + (recv_rate * recv_attempts * 0.05) + (serve_effect_rate * serve_attempts * 0.05)
  end
end