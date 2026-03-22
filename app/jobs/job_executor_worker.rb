class JobExecutorWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  HEARTBEAT_INTERVAL = 20
  HEARTBEAT_TTL = 60
  MAX_RETRIES = 5

  def perform(job_id)
    job = Job.find(job_id)
    return unless job.running?

    start_heartbeat(job)

    execute_workload(job)

    mark_completed(job)
  rescue => e
    handle_failure(job, e)
  ensure
    stop_heartbeat(job)
  end

  private
    def start_heartbeat(job)
      @heartbeat_thread = Thread.new do
        loop do
          break unless job.running?

          REDIS.set(
            heartbeat_key(job.id),
            Time.now.to_i,
            ex: HEARTBEAT_TTL
          )

          sleep HEARTBEAT_INTERVAL
        end
      end
    end

    def stop_heartbeat(job)
      @heartbeat_thread&.kill
      REDIS.del(heartbeat_key(job.id))
    end

    def heartbeat_key(job_id)
      "job_heartbeat:#{job_id}"
    end

    def execute_workload(job)
      case job.workload
      when "task_1"
        puts ">>>>> Executing the workload: task_1 <<<<<"
      when "task_2"
        puts ">>>>> Executing the workload: task_2 <<<<<"
      else
        puts ">>>>> Executing the workload: other <<<<<"
      end
    end

    def mark_completed(job)
      job.with_lock do
        return unless job.running?

        job.complete!

        # Scheduling new job starts without requiring a restart
        SchedulerWorker.perform_async
      end
    end

    def handle_failure(job, error)
      job.with_lock do
        return unless job.running?

        job.retry_count += 1

        if job.retry_count > MAX_RETRIES
          job.fail!
        else
          schedule_retry(job)
        end
      end
    end

    def schedule_retry(job)
      delay = (2 ** job.retry_count) * 30

      job.update!(status: :queued)

      SchedulerWorker.perform_in(delay)
    end
end