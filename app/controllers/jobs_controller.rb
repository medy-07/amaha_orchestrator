class JobsController < ApplicationController
  def create
    job = Job.create!(job_params)

    SchedulerWorker.perform_async

    render json: { job_id: job.id, status: job.status }, status: :created
  rescue ActiveRecord::InvalidForeignKey
  	render json: { error: "Client not found" }, status: :not_found
  end

  private
    def job_params
      params.permit(:client_id, :priority, :workload)
    end
end