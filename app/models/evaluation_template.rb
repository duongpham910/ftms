class EvaluationTemplate < ApplicationRecord
  acts_as_paranoid

  ATTRIBUTES_PARAMS = [:name, :min_point, :max_point]

  has_many :evaluation_details

  validates :name, presence: true
  validates :min_point, presence: true, numericality: {greater_than: 0, less_than_or_equal_to: :max_point}
  validates :max_point, presence: true, numericality: true
end
