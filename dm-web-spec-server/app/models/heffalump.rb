class Heffalump < ActiveRecord::Base
  attr_accessible :color, :num_spots, :striped
  validates :color, presence: true, length: { minimum: 3 }
end
