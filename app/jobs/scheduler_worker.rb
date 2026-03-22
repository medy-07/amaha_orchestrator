class SchedulerWorker
  include Sidekiq::Worker

  def perform
    clients_jobs = fetch_jobs_grouped_by_client

    clients_jobs.each do |client_id, jobs|
      process_client_jobs(client_id, jobs)
    end

    # Scheduling new job starts without requiring a restart
    SchedulerWorker.perform_in(1.second)
  end

  private

    def fetch_jobs_grouped_by_client
      Job.queued
        .order(priority: :desc, created_at: :asc)
        .limit(200)
        .group_by(&:client_id)
    end

    def process_client_jobs(client_id, jobs)
      client = Client.find(client_id)

      available_slots = get_available_slots(client)

      return if available_slots <= 0

      jobs.first(available_slots).each do |job|
        start_job(job)
      end
    end

    def get_available_slots(client)
      running_count = Job.where(client_id: client.id, status: :running).count
      client.concurrency_limit - running_count
    end

    def start_job(job)
      job.with_lock do
        return unless job.queued?

        job.start!

        JobExecutorWorker.perform_async(job.id)
      end
    end
end