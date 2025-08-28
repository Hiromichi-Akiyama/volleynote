class Match < ApplicationRecord
  belongs_to :user
  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players
  
  validates :status, presence: true
  
  enum status: { preparing: 0, active: 1, completed: 2 }
  
  scope :recent, -> { order(created_at: :desc) }
end