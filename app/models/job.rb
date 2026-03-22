# frozen_string_literal: true

class Job < ApplicationRecord
  include AASM

  belongs_to :client

  before_create :set_id

  enum status: { queued: 0, running: 1, completed: 2, failed: 3, stalled: 4 }
  enum priority: { low: 0, medium: 1, high: 2 }

  aasm column: :status do
    state :queued, initial: true
    state :running
    state :completed
    state :failed
    state :stalled

    event :start do
      transitions from: :queued, to: :running
    end

    event :complete do
      transitions from: :running, to: :completed
    end

    event :fail do
      transitions from: :running, to: :failed
    end

    event :stall do
      transitions from: :running, to: :stalled
    end
  end

  private
    def set_id
      self.id ||= SecureRandom.uuid
    end
end
