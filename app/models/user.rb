class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :players, dependent: :destroy
  has_many :matches, dependent: :destroy
  
  validates :team_name, presence: true
end