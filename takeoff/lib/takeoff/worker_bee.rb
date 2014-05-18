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


      @aws = Aws::EC2.new
      @cloudformation = Aws::CloudFormation.new

    end

    def create_workers(number_of_instances, instance_data = {})
      options = {
          stack_name: "Pollinator-#{Time.now.to_i}",
          template_body: "#{File.read(File.join(File.dirname(__FILE__), "../bootstrap/cloudformulation.json")).gsub("\n\r", "")}",
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

      #threads = []
      # number_of_instances.times do |index|
      #   threads << Thread.new do
      #     worker.launch_instance(image_id, instance_type, user_data, options[:user_id])
      #   end
      # end
      #threads.each { |t| t.join }


      # resp = @cloudformation.create_stack(options)
      # stack_id = resp.stack_id
      # pp "Start template created: #{resp.stack_id}"
      #
      # resp = @cloudformation.start_stack(
      #     stack_id: resp.stack_id,
      # )

      stack_id = "arn:aws:cloudformation:us-west-2:471211731895:stack/Pollinator-1400383912/f2865220-de3c-11e3-a914-507bfc8840a6"
      instances = describe_running_instances(stack_id)
      instance_id = instances.first[:instance_id]

      # get the instance information
      test_result = @aws.describe_instance_status(instance_ids: [instance_id]).data.instance_statuses.first
      begin
        Timeout.timeout(1800) {# 30 minutes
          while test_result.nil? || test_result.instance_state.name != 'running'
            # refresh the server instance information

            sleep 5
            test_result = @aws.describe_instance_status(instance_ids: [aws_instance.instance_id]).data.instance_statuses.first
            logger.info '... waiting for instance to be running ...'
          end
          puts "Instance is running"
          puts "Public IP #{instances.first[:public_ip_address]}"
        }
      rescue TimeoutError
        raise "Intance was unable to launch due to timeout #{aws_instance.instance_id}"
      end

      # Send the data to the systems

      # HOOOOW

      



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

    # return all of the running instances, or filter by the group_uuid & instance type
    def describe_running_instances(stack_id = nil)
      resp = nil
      resp = @aws.describe_instances(

          filters: [
              {name: 'instance-state-code', values: [0.to_s, 16.to_s]}, # running or pending
              {name: 'tag-value', values: [stack_id]},
          # {:name => "tag-value", :values => [group_uuid.to_s, "OpenStudio#{@openstudio_instance_type.capitalize}"]}
          # {:name => "tag:key=value", :values => ["GroupUUID=#{group_uuid.to_s}"]}
          ]

      )

      instance_data = nil
      if resp
        if resp.reservations.length > 0
          resp = resp.reservations.first
          if resp.instances
            instance_data = []
            resp.instances.each do |i|
              instance_data << i.to_hash
            end

          end
        else
          logger.info 'no running instances found'
        end
      end

      instance_data
    end
  end
end