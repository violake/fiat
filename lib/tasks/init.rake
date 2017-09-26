require_relative "../../service/amqp_queue"
namespace :init do
  desc "init fiat queue"
  task :fiat_queues do
    AMQPQueue.queue
    AMQPQueue.subscribe_queue
  end
end