# frozen_string_literal: true

# Models multiple kinds of events
class Event < ApplicationRecord
  scope :openings, -> { where(kind: 'opening') }
  scope :appointments, -> { where(kind: 'appointment') }
  scope :next_n_days, ->(given_day, n_days_in_future) { where('starts_at > ? AND starts_at < ?', given_day, n_days_in_future) }

  def self.availabilities(customers_date)
    Array.new(7) do |day|
      next_day = (customers_date + day)
      {
        date: next_day.strftime('%Y/%m/%d'),
        slots: find_available_slots(next_day)
      }
    end
  end
end
