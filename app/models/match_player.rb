class MatchPlayer < ApplicationRecord
  belongs_to :match
  belongs_to :player
  
  validates :player_id, uniqueness: { scope: :match_id }
  
  enum role: { starting: 0, bench: 1 }
  enum court_status: { on_court: 0, on_bench: 1, excluded: 2 }
end