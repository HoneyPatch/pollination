module Takeoff
  class WorkerBee

    include TakeoffMethods

    def initialize()
      @instances = []
      @logger = Logger.new('takeoff.log')
      @cloudformation = nil
    end

    def create_workers(number_of_instances, instance_data = {})
      defaults = {instance_type: 'm2.4xlarge'}
      instance_data = defaults.merge(instance_data)

      instance_data[:image_id] = 'TODO: WHAT IS MY ID'


      @cloudformation = setup_cloudformation
      launch_workers(number_of_instances, instance_data)



      # puts ''
      # puts 'Worker SSH Command:'
      # @os_aws.workers.each do |worker|
      #   puts "ssh -i #{@local_key_file_name} ubuntu@#{worker.data[:dns]}"
      # end
      #
      # puts ''
      # puts 'Waiting for server/worker configurations'

      #configure_server_and_workers
    end


    private


    def setup_cloudformation

    end
    def launch_workers(number_of_instances, instance_data)
      # TODO: store the data about the instances some
      (1..number_of_instances).each do |instance|
        @instances << launch_instance()
      end


    end
  end
end