<!-- Distributed Task Orchestrator - Design -->

This system is designed in a way that ensures:
  - Fairness Scheduling across clients
  - Strict Job concurrency limits per client
  - Fault tolerance via heartbeat detection

The architecture separates responsibilities into:
 - API layer (job creation)
 - Scheduler (job selection)
 - Executor (job processing)
 - Monitoring (health + stalled job detection)

1. Scaling to 100k Jobs/Hour:
  1.1 Batch Processing:
    - Scheduler processes jobs in batches (e.g., 100–200 per run)
    - Prevents loading entire queue into memory
  1.2 Database Optimization:
  	- Indexing ensures efficient querying for queued and running jobs
  1.3 Redis Usage Optimization:
  	- It is used to maintain heartbeat to detect stalled jobs
  1.4 Sharding:
  	- System can be horizontally scaled by partitioning jobs by "client_id"
  1.5 Scheduler & Executor Separation:
  	- Scheduler: Select jobs based on priority, fairness.
  	- Executor:  Execute job workload and maintain heartbeat

2. Failure Modes:
  2.1 What happens if Redis loses all keys (flushall)?
  	- All heartbeat keys are deleted
  	- Running jobs appear dead and will be marked as stalled
  2.2 How do you handle a "split-brain" where two workers try to stall the same job?
  	- Use database row-level locking
  2.3 How do you handle a worker that is "frozen" (e.g., long GC pause) for 2 minutes?
  	- Redis key expires in TTL
  	- Worker marks those jobs as stalled

3. Abuse Protection:
  3.1 If a client submits 1 million jobs in 10 seconds, how do you ensure the system remains responsive for others?
  	- Concurrency Limits: Each client has concurrency_limit
  	- Fair Scheduling: Scheduler processes each client independently and Prevents starvation
  	- Rate Limiting: Can limit job creation per client. We can implement this using redis counters.

4. Retry Strategy:
  - We use "At Least Once" processing:
  	- Jobs may execute more than once
  	- Ensured safe via:
  	  - Idempotent job execution
  	  - State checks before execution
  	- Controller via retry count in DB
  	- Retries go through scheduler (respect concurrency limits)

5. Fairness Scheduling Approach:
  - I have tried implementing "Weighted Fair Queuing":
  	- where each client gets a weight(quota)
  	- more the weight more jobs allowed for processing
  - Approach:
  	- Jobs are fetched in batches ordered by priority and creation time
  	- the batch is groped_by "client_id"
  	- Each client is allowed to start jobs up to its configured 'concurrency_limit'.
  - Fairness:
  	- Each client receives 'concurrency_limit'
  	- Clients with higher limits are allowed to process more jobs.
  	- Clients with lower limits still receive guaranteed execution slots.
  - Starvation Prevention:
  	- Jobs are grouped by client and processed in each scheduler cycle, every client in the batch gets an opportunity to execute jobs.
  	- Batch limiting ('LIMIT 200') ensures that no single client can dominate the scheduler input.
  	- Continuous scheduling ('perform_in(1.second)') ensures that newly available slots are quickly utilized.
