class Transaction < ActiveRecord::Base
  validates :zhash, presence: true
end