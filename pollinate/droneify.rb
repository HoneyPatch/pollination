# TODO: put this into a gem file


# Install the following gems
# gem install uuid

require 'fileutils'
require 'thread'
require 'uuid'
require 'pp'

NUMBER_OF_PROCESSORS = 8

class Droneify
  def initialize(grasshopper_definition)
    @grasshopper_definition = grasshopper_definition

  end

  def tracker_jacker(json_file, destination_directory, &block)
    pp "running #{json_file}"
    json_dir = File.dirname(json_file)

    random = UUID.new.generate
    dest_dir = "#{destination_directory}/job_#{random}/input"
    final_dir = "#{destination_directory}/job_#{random}/results"
    FileUtils.mkdir_p(dest_dir)
    FileUtils.mkdir_p(final_dir)

    # Copy in the gh if it is not there
    unless File.exist? "#{dest_dir}/#{File.basename(@grasshopper_definition)}"
      FileUtils.copy @grasshopper_definition, "#{dest_dir}/#{File.basename(@grasshopper_definition)}"
    end
    FileUtils.copy(json_file, "#{dest_dir}/ParamSet.json")

    #sleep 5

    faux_wait = 1
    receipt_file = "#{final_dir}/done.receipt"
    until File.exist?(receipt_file) # || timeout !
      faux_wait += 1

      if faux_wait >= 10
        File.open(receipt_file, 'w') { |f| f << "#{Time.now}" }
      end
      sleep 1
    end
    # put a wathc on this
  end

  # chunk up all of the files and put them into their own directory
  def swarm(json_file_directory, destination_directory)
    queue = Queue.new
    threads = []

    FileUtils.rm_rf(destination_directory)
    # add the jsons to the queue to process
    queue = Dir["#{json_file_directory}/*.json"]

    puts "Queue to run is:"
    puts queue
    NUMBER_OF_PROCESSORS.times do
      threads << Thread.new do
        until queue.empty?
          bee = queue.pop #(true)
          if bee
            tracker_jacker(bee, destination_directory)
          end
        end

        # TODO: what next?
        puts "Done"
      end
    end

    threads.each { |t| t.join }
  end

end


# this is cheeze... but putting the script call here
drone = Droneify.new("#{File.dirname(__FILE__)}/DefMaster.gh")
drone.swarm("#{File.dirname(__FILE__)}/json_instances", "#{File.dirname(__FILE__)}/Swarm")


