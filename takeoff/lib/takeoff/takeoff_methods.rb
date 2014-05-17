module Takeoff
  module TakeoffMethods

    # Launch data contains the datat to start the instance
    #   param image_id: amazon image id
    #   param instance_type: i.e. m3.large
    #   param user_data: user infomration including bootstrap script
    def launch_instance(image_id, instance_type, user_data)



      # logger.info("user_data #{user_data.inspect}")
      # instance = {
      #     image_id: image_id,
      #     key_name: @key_pair_name,
      #     security_groups: [@security_group_name],
      #     user_data: Base64.encode64(user_data),
      #     instance_type: instance_type,
      #     min_count: 1,
      #     max_count: 1
      # }
      # logger.info instance.inspect
      # result = @aws.run_instances(instance)
      #
      # # determine how many processors are suppose to be in this image (lookup for now?)
      # processors = find_processors(instance_type)
      #
      # # only asked for 1 instance, so therefore it should be the first
      # aws_instance = result.data.instances.first
      # @aws.create_tags(
      #
      #     resources: [aws_instance.instance_id],
      #     tags: [
      #         { key: 'Name', value: "OpenStudio-#{@openstudio_instance_type.capitalize}" }, # todo: abstract out the server and version
      #         { key: 'GroupUUID', value: @group_uuid },
      #         { key: 'NumberOfProcessors', value: processors.to_s },
      #         { key: 'Purpose', value: "OpenStudio#{@openstudio_instance_type.capitalize}" }
      #     ]
      #
      # )
      #
      # # get the instance information
      # test_result = @aws.describe_instance_status(instance_ids: [aws_instance.instance_id]).data.instance_statuses.first
      # begin
      #   Timeout.timeout(600) {# 10 minutes
      #     while test_result.nil? || test_result.instance_state.name != 'running'
      #       # refresh the server instance information
      #
      #       sleep 5
      #       test_result = @aws.describe_instance_status(instance_ids: [aws_instance.instance_id]).data.instance_statuses.first
      #       logger.info '... waiting for instance to be running ...'
      #     end
      #   }
      # rescue TimeoutError
      #   raise "Intance was unable to launch due to timeout #{aws_instance.instance_id}"
      # end
      #
      # # now grab information about the instance
      # # todo: check lengths on all of arrays
      # instance_data = @aws.describe_instances(instance_ids: [aws_instance.instance_id]).data.reservations.first.instances.first.to_hash
      # @logger.info "instance description is: #{instance_data}"
      #
      # @data = instance_data
    end
  end
end