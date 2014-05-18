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

    def create_workers(number_of_instances)
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
                  parameter_value: "m1.small"
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
      number_of_instances.times do |index|
        #threads << Thread.new do
          puts "Launcing system #{index}"
          @instances << {:index => index, :data => launch_worker(options)}
        #end
      end
      threads.each { |t| t.join }

      File.rm "instances.json" if File.exist? "instances.json"
      File.open("instances.json",'w') { |f| f << JSON.pretty_generate({:instances => @instances})}

    end


    private

    def launch_worker(options)
      resp = @cloudformation.create_stack(options)
      stack_id = resp.stack_id
      pp "Start template created: #{resp.stack_id}"

      stack_name = options[:stack_name]
      #stack_name = "Pollinator-1400390557"
      #stack_id = "arn:aws:cloudformation:us-west-2:471211731895:stack/Pollinator-1400388047/93060890-de46-11e3-ac7a-500160d4da18"
      status = 'unknown'
      resp = nil
      begin
        Timeout.timeout(900) {# 20 minutes
          until status == 'CREATE_COMPLETE'
            begin
              resp = @cloudformation.describe_stack_resource(stack_name: stack_name, logical_resource_id: "WindowsServerWaitCondition")[:stack_resource_detail]
              status = resp[:resource_status]
            rescue
            end
            print "."
            sleep 5
          end
        }
      end

      resp = @cloudformation.describe_stack_resource(stack_name: stack_name, logical_resource_id: "WindowsServer")[:stack_resource_detail]
      instance_id = resp[:physical_resource_id]
      pp "CloudFormation is waiting checking amazon instance #{instance_id}"

      # get the instance information
      test_result = nil
      begin
        Timeout.timeout(1800) {# 30 minutes
          while test_result.nil? || test_result.instance_state.name != 'running'
            # refresh the server instance information

            sleep 5
            begin
              test_result = @aws.describe_instance_status(instance_ids: [instance_id]).data.instance_statuses.first
            rescue
            end

            @logger.info '... waiting for instance to be running ...'
          end
          puts "Instance is running"
          puts "Getting details"
          detail_info = describe_running_instances(stack_id).first
          puts "Public IP #{detail_info[:public_ip_address]}"
        }
      rescue TimeoutError
        raise "Instance was unable to launch due to timeout #{aws_instance.instance_id}"
      end

      detail_info
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
          @logger.info 'no running instances found'
        end
      end

      instance_data
    end
  end
end