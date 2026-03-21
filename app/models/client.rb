# frozen_string_literal: true

class Client < ApplicationRecord
  before_create :set_id

  has_many :jobs, dependent: :destroy

  private
    def set_id
      self.id ||= SecureRandom.uuid
    end
end
