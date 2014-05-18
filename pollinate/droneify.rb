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
    # create a hash to track which processor is being used

    @processor_tracker = {}
    NUMBER_OF_PROCESSORS.times do |processor|
      @processor_tracker[processor] = {available: true, initialized: false}
      create_run_directories(processor)
    end
  end

  def tracker_jacker(json_file, processor_id, base_destination_directory, &block)
    pp "running #{json_file}"
    json_dir = File.dirname(json_file)

    random = UUID.new.generate
    destination_directory = "#{base_destination_directory}/job_#{random}"
    FileUtils.mkdir_p(destination_directory)
    param_file = File.read(json_file)
    File.open("#{destination_directory}/ParamSet.json", 'w') { |f| f << param_file }

    # Also copy to the run directory
    run_dir = "#{File.dirname(__FILE__)}/Run/Processor_#{processor_id}"
    fail "Run dir missing #{run_dir}" unless File.exist? run_dir

    # first copy in the paramset
    FileUtils.copy(json_file, "#{run_dir}/ParamSet.json")

    # then add the rhino
    initialize_rhino(processor_id) unless @processor_tracker[processor_id][:initialized]

    receipt_file = "#{run_dir}/done.receipt"
    until File.exist?(receipt_file) # || timeout !
      sleep 1
    end

    # Move the results out of the run directories
    results = Dir["#{run_dir}/*"]
    results.each do |r|
      pp "moving file #{r} to #{destination_directory}"
      if File.extname(r).downcase == '.gh' || File.basename(r) == 'launch.receipt'
        pp "skipping file #{r}"
      else
        FileUtils.move(r, "#{destination_directory}/#{File.basename(r)}")
      end
    end
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
            processor_id = get_available_processor
            @processor_tracker[processor_id][:available] = false
            tracker_jacker(bee, processor_id, destination_directory)
            @processor_tracker[processor_id][:available] = true
          end
        end

      end
    end
    puts "Done with all the threads"

    threads.each { |t| t.join }
  end

  private

  def get_available_processor
    @processor_tracker.find { |k, _| @processor_tracker[k][:available] == true }.first
  end

  def create_run_directories(processor_id)
    # Force removal of the directory if there
    d = File.expand_path("#{File.dirname(__FILE__)}/Run/Processor_#{processor_id}")
    FileUtils.rm_rf d
    FileUtils.mkdir_p d
  end

  def initialize_rhino(processor_id)
    # stage the grasshopper file
    d = File.expand_path("#{File.dirname(__FILE__)}/Run/Processor_#{processor_id}")
    unless File.exist? "#{d}/#{File.basename(@grasshopper_definition)}"
      d_def = File.expand_path("#{d}/#{File.basename(@grasshopper_definition)}")
      #rhino_location = "/Applications/Microsoft\ Office\ 2011/Microsoft\ Word.app"
      rhino_location = "C:/Program Files/Rhinoceros\ 5\ (64-bit)/System/Rhino.exe"
      FileUtils.copy @grasshopper_definition, "#{d}/#{File.basename(@grasshopper_definition)}"
      if File.exist? rhino_location
        pp "Creating run directory and launching app for #{d}"
        #syscall = "open \"#{rhino_location}\""# /runscript=\"-Grasshopper Editor Load Editor Show Enter -Grasshopper Document Open \"\"#{d_def}\"\" Enter\""
        syscall = "\"#{rhino_location}\" /runscript=\"-Grasshopper Editor Load Editor Show Enter -Grasshopper Document Open \"\"#{d_def}\"\" Enter\""
        IO.popen("#{syscall}")
        until File.exist? "#{d}/launch.receipt"
          print "."
          sleep 5
        end
        pp "I have launched"
      else
        puts "WARNING: Can't find Rhino"
      end
    end
    @processor_tracker[processor_id][:initialized] = true
  end

end


# this is cheeze... but putting the script call here
drone = Droneify.new("#{File.dirname(__FILE__)}/DefMaster.gh")
drone.swarm("#{File.dirname(__FILE__)}/Instances", "#{File.dirname(__FILE__)}/Swarm")


