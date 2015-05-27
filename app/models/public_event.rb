class PublicEvent < ActiveRecord::Base
  belongs_to :user
  attr_accessible :user, :data
  validates :user, presence: true
  validates :data, presence: true
  serialize :data, JSON
end