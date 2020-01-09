# frozen_string_literal: true

# Models multiple kinds of events
class Event < ApplicationRecord
  scope :openings, -> { where(kind: 'opening') }
  scope :appointments, -> { where(kind: 'appointment') }
  scope :next_n_days, ->(given_day, n_days_in_future) { where('starts_at > ? AND starts_at < ?', given_day, n_days_in_future) }
  # To-Do: I want to use %D to be more specific about the date,
  # but can't get the format to work with the scope query.
  scope :for_given_day, ->(given_day) { where("strftime('%j', starts_at) = strftime('%j', ?)", given_day) }
  scope :recurs_weekly, ->(given_day) { where("weekly_recurring = true AND strftime('%w', starts_at) = strftime('%w', ?)", given_day) }

  def self.availabilities(customers_date)
    Array.new(7) do |day|
      next_day = (customers_date + day)
      {
        date: next_day.strftime('%Y/%m/%d'),
        slots: find_available_slots(next_day)
      }
    end
  end

  def self.find_available_slots(given_day)
    nonrecurring_openings = Event.for_given_day(given_day.to_date).openings
    weekly_recurring_openings = Event.recurs_weekly(given_day).openings
    all_upcoming_openings = nonrecurring_openings + weekly_recurring_openings
    available_slots = slotify(all_upcoming_openings).flatten(1)
  end

  def self.slotify(openings)
    openings.map do |open_event|
      (open_event.starts_at.to_i...open_event.ends_at.to_i).step(30.minutes).map do |time_slot|
        Time.zone.at(time_slot)
      end
    end
  end
end
