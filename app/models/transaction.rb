class Transaction < ActiveRecord::Base
  validates :zhash, presence: true
  validates :zhash, uniqueness: true
end