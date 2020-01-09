# frozen_string_literal: true

# Models multiple kinds of events
class Event < ApplicationRecord
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
