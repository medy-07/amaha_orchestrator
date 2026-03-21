# frozen_string_literal: true

class Job < ApplicationRecord
  include AASM

  belongs_to :client

  aasm column: :status do
    state :queued, initial: true
    state :running
    state :completed
    state :failed
    state :stalled
  end
end
