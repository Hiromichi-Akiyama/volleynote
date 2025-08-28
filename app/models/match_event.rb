class MatchEvent < ApplicationRecord
  belongs_to :match
  belongs_to :player
  
  validates :event_type, presence: true, inclusion: { 
    in: %w[spike_attempt spike_kill recv_attempt recv_success serve_attempt serve_effect serve_point] 
  }
  validates :value, presence: true
  validates :occurred_at, presence: true
  
  before_validation :set_default_occurred_at, if: -> { occurred_at.blank? }
  
  scope :spikes, -> { where(event_type: ['spike_attempt', 'spike_kill']) }
  scope :receives, -> { where(event_type: ['recv_attempt', 'recv_success']) }
  scope :serves, -> { where(event_type: ['serve_attempt', 'serve_effect', 'serve_point']) }
  
  private
  
  def set_default_occurred_at
    self.occurred_at = Time.current
  end
end