require 'fileutils'
require 'json'

# Utility class wrapping the various command line tools available with xcode.
class XcodeTools

    # Run xcodebuild commands
    #
    # @param command [Symbol, String] the command to invoke
    # @param scheme [String] the scheme to build
    # @param destination [String, Device] the destination to run the project on
    # @param sdk [String] what sdk to use for the build, defaults to 'iphonesimulator'
    def self.xcodebuild(command, scheme, destination, sdk = 'iphonesimulator')
        dest = destination.is_a?(Device) ? destination.to_destination : destination
        system "xcodebuild #{command} -scheme #{scheme} -destination '#{dest}' -sdk #{sdk} -derivedDataPath build | xcpretty"
    end

    # Run `xcrun simctl` commands
    #
    # @param command [Symbol, String] the command to invoke
    # @param args [Array] arguments to pass to the command
    # @return [String] the output of the command
    def self.simctl(command, *args)
        shell "xcrun simctl #{command} #{args * ' '}"
    end

    # Executes a command in the shell, aborts on non-zero exit codes.
    #
    # @param command [String] the entire shell command to run
    # @return [String] the output of the command
    def self.shell(command)
        output = `#{command}`
        abort("#{command} failed with exit code #{$?}") unless $? == 0
        return output
    end

end

# Devices available to Xcode for running and testing project on.
#
# NOTE: Currently only iOS devices are supported.
class Device
    attr_accessor :availability, :state, :name, :udid, :os

    # Loads the list of devices present on the machine by parsing the JSON output of
    # `xcrun simctl list -j devices`.
    #
    # NOTE: Currently only deals with iOS devices for now.
    #
    # @return [Array] all the devices found.
    def self.load_devices
        output = XcodeTools.simctl(:list, '-j', 'devices')
        list = JSON.parse(output)
        abort("Device list was not in the expected format") unless list.has_key? 'devices'
        list = list['devices']
        parsed = []
        list.each do |os, devices|
            next unless os.start_with? 'iOS'    # non-iOS devices have a different set of keys
            devices.each { |info| parsed << Device.new(os, info) }
        end
        return parsed
    end

    # Initializer.
    #
    # @param os [String] the full operating system identifier
    # @param info [Hash] the attributes of the device
    def initialize(os, info)
        @availability = info['availability'][1..-2] # trim the brackets
        @state = info['state'].downcase.to_sym
        @name = info['name']
        @udid = info['udid']
        @os = os
    end

    # @return true if the device is listed as available
    def available?
        @availability == 'available'
    end

    # @return true if the device is an iPhone
    def iphone?
        @name.include? 'iPhone'
    end

    # @return true if the device is an iPad
    def ipad?
        @name.include? 'iPad'
    end

    # @return [Symbol] the operating system family for the device `iOS, OSX` etc...
    def os_family
        @os.split("\s")[0].strip.to_sym
    end

    # @return [Float] the version number of the os
    def os_version
        @os.split("\s")[1].strip.to_f
    end

    # Converts this device to a destination specifier for passing to xcodebuild.
    #
    # @param platform [String] the platform part of the destination, defailts to 'iOS Simulator'
    # @return [String] the destination specifier string
    def to_destination(platform = 'iOS Simulator')
        "platform=#{platform},id=#{@udid}"
    end

    def to_s
        "Device(name: %s, os: %s, availability: (%s), state: %s, udid: %s)" % [@name, @os, @availability, @state, @udid]
    end

    def to_hash
        instance_variables.inject(Hash.new) { |hash, name| hash[name[1..-1]] = instance_variable_get(name) }
    end

end

# Picks the target device for testing.
def target_device(min_ios = 8.0)
    devices = Device.load_devices.sort_by { |d| d.os_version }
    target = devices.find { |d| d.available? && d.iphone? && d.os_version >= min_ios && d.name == 'iPhone 6' }
    abort "could not find a compatible device" unless target
    puts "Using target device: #{target}"
    return target
end

task :test do
    XcodeTools.xcodebuild(:test, 'NatureNet', target_device)
end

task :unit do
    XcodeTools.xcodebuild(:test, 'NNUnitTests', target_device)
end

task :'ui-test' do
    # ui automation requires the device to be iOS 9.0 or higher
    XcodeTools.xcodebuild(:test, 'NNUITests', target_device(9.0))
end

task :clean do
    FileUtils.rm_rf('./build') if File.exists? './build'
    devices = [target_device, target_device(9.0)]
    devices.each do |device|
        XcodeTools.simctl(:shutdown, device.udid) if device.state == :booted
        XcodeTools.simctl(:erase, device.udid)
    end
end

