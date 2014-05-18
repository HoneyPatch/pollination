module Takeoff
  class WorkerBee

    def initialize
      @instances = []
      @logger = Logger.new('takeoff.log')
      @cloudformation = nil



      # Make sure to put your data into the $HOME/.aws/credentials files
      # [default]
      # aws_access_key_id=ENTER_KEY
      # aws_secret_access_key=ENTER_SECRET_KEY
      # region=us-west-2

      Aws.config[:region] = 'us-west-2'
      Aws.config[:cloudformation] = {region: 'us-west-2'}

      @cloudformation = Aws::CloudFormation.new

    end

    def create_workers(number_of_instances, instance_data = {})
      options = {
          stack_name: "Pollinator-#{Time.now.to_i}",
          template_body: "#{File.read(File.join(File.dirname(__FILE__), "../bootstrap/cloudformulation.json")).gsub("\n\r","")}",
          parameters: [
              {
                  parameter_key: "Features",
                  parameter_value: "None"
              },
              {
                  parameter_key: "InstanceType",
                  parameter_value: "m1.large"
              },
              {
                  parameter_key: "KeyPairName",
                  parameter_value: "pollinator-hackathon"
              },
              {
                  parameter_key: "SourceCidrForRDP",
                  parameter_value: "0.0.0.0/0"
              },
              {
                  parameter_key: "Roles",
                  parameter_value: "None"
              }
          ],
          timeout_in_minutes: 1800,
          on_failure: "ROLLBACK",
          tags: [
              {
                  key: "Pollinator",
                  value: "Worker",
              },
          ]
      }
      pp options
      resp = @cloudformation.create_stack(options)
      stack_id = resp.stack_id
      pp "Start template created: #{resp.stack_id}"

      resp = @cloudformation.start_stack(
          stack_id: resp.stack_id,
      )

      pp resp


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