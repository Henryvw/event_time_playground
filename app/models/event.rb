# frozen_string_literal: true

# Models multiple kinds of events
class Event < ApplicationRecord
  scope :openings, -> { where(kind: 'opening') }
  scope :appointments, -> { where(kind: 'appointment') }

  # I didn't end up using this scope. But might be useful in future.
  scope :next_n_days, lambda { |given_day, n_days_in_future|
    where('starts_at > ? AND starts_at < ?', given_day, n_days_in_future)
  }

  # To-Do: I want to use %D to be more specific about the date,
  # but can't get the format to work with the scope query.
  scope :for_given_day, lambda { |given_day|
    where("strftime('%j', starts_at) = strftime('%j', ?)", given_day)
  }

  scope :recurs_weekly, lambda { |given_day|
    where("weekly_recurring = true
          AND strftime('%w', starts_at) = strftime('%w', ?)",
          given_day)
  }

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
    weekly_openings = Event.recurs_weekly(given_day).openings
    all_upcoming_openings = nonrecurring_openings + weekly_openings
    available_slots = slotify(all_upcoming_openings).flatten(1)
    available_slots - compare_against_appointments(given_day)
  end

  def self.slotify(openings)
    openings.map do |open_event|
      (open_event.starts_at.to_i...open_event.ends_at.to_i).step(30.minutes)
                                                           .map do |time_slot|
        format_into_hour_string(Time.zone.at(time_slot))
      end
    end
  end

  def self.format_into_hour_string(time)
    time.strftime('%-k:%M')
  end

  def self.compare_against_appointments(given_day)
    nonrecurring_appointments = Event.for_given_day(given_day).appointments
    weekly_appointments = Event.recurs_weekly(given_day).appointments
    all_upcoming_appointments = nonrecurring_appointments + weekly_appointments
    slotify(all_upcoming_appointments).flatten(1)
  end
end
