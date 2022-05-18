class Budget
  class HeadingType < ActiveRecord::Base
    HEADING_KINDS = %w(sector suburb).freeze

    belongs_to :budget
    #belongs_to :next_phase, class_name: 'Budget::Phase', foreign_key: :next_phase_id
    #has_one :prev_phase, class_name: 'Budget::Phase', foreign_key: :next_phase_id

    #validates :budget, presence: true
    #validates :kind, presence: true, uniqueness: { scope: :budget }, inclusion: { in: PHASE_KINDS }
    #validates :summary, length: { maximum: SUMMARY_MAX_LENGTH }
    #validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }
    #validate :invalid_dates_range?
    #validate :prev_phase_dates_valid?
    #validate :next_phase_dates_valid?

    #before_validation :sanitize_description

    #after_save :adjust_date_ranges
    #after_save :touch_budget

    #scope :enabled,           -> { where(enabled: true) }
    #scope :published,         -> { enabled.where.not(kind: 'drafting') }
    scope :sector,          -> { find_by_kind('sector') }
    scope :suburb,         -> { find_by_kind('suburb') }

  end
end
