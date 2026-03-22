class StalledJobDetectorWorker
  include Sidekiq::Worker

  def perform
    Job.running.find_each do |job|
      check_and_stall(job)
    end
  end

  private

    def check_and_stall(job)
      heartbeat = REDIS.get(heartbeat_key(job.id))

      return if heartbeat.present?

      job.with_lock do
        return unless job.running?

        job.stall!
      end
    end

    def heartbeat_key(job_id)
      "job_heartbeat:#{job_id}"
    end
end