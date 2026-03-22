require 'sidekiq/api'

class HealthController < ApplicationController
  def detailed
    db_status = check_db
    redis_status = check_redis
    sidekiq_latency = sidekiq_latency()

    healthy = db_status && redis_status && sidekiq_latency < 15

    status_code = healthy ? :ok : :service_unavailable

    render json: {
      database: db_status ? "ok" : "down",
      redis: redis_status ? "ok" : "down",
      sidekiq_latency: sidekiq_latency,
      status: healthy ? "healthy" : "unhealthy"
    }, status: status_code
  end

  private

  def check_db
    ActiveRecord::Base.connection.active?
  rescue
    false
  end

  def check_redis
    REDIS.ping == "PONG"
  rescue
    false
  end

  def sidekiq_latency
    Sidekiq::Queue.new.latency
  end
end