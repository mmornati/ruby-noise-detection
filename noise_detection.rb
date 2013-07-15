#!/usr/bin/ruby -w
#
# Copyright (C) 2013 Marco Mornati [http://www.mornati.net]
# Based on Thomer M. Gil First [http://thomer.com/] version template
#
# Oct  05, 2012: Initial version
#
# This program is free software. You may distribute it under the terms of
# the GNU General Public License as published by the Free Software
# Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# This program detects the presence of sound and invokes a program.
#

require 'getoptlong'
require 'optparse'
require 'net/smtp'
require 'logger'
require 'date'


HW_DETECTION_CMD = "cat /proc/asound/cards"
# You need to replace MICROPHONE with the name of your microphone, as reported
# by /proc/asound/cards
SAMPLE_DURATION = 5 # seconds
FORMAT = 'S16_LE'   # this is the format that my USB microphone generates
THRESHOLD = 0.05
RECORD_FILENAME='/tmp/noise.wav'
LOG_FILE='/var/log/noise_detector.log'
PID_FILE='/etc/noised/noised.pid'

logger = Logger.new(LOG_FILE)
logger.level = Logger::DEBUG

logger.info("Noise detector started @ #{DateTime.now.strftime('%d/%m/%Y %H:%M:%S')}")


def self.check_required()
  if !File.exists?('/usr/bin/arecord')
    warn "/usr/bin/arecord not found; install package alsa-utils"
    exit 1
  end

  if !File.exists?('/usr/bin/sox')
    warn "/usr/bin/sox not found; install package sox"
    exit 1
  end

  if !File.exists?('/proc/asound/cards')
    warn "/proc/asound/cards not found"
    exit 1
  end
  
end

# Parsing script parameters
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: noise_detection.rb -m ID [options]"

  opts.on("-m", "--microphone SOUND_CARD_ID", "REQUIRED: Set microphone id") do |m|
    options[:microphone] = m
  end
  opts.on("-s", "--sample SECONDS", "Sample duration") do |s|
    options[:sample] = s
  end
  opts.on("-n", "--threshold NOISE_THRESHOLD", "Set Activation noise Threshold. EX. 0.1") do |n|
    options[:threshold] = n
  end
  opts.on("-e", "--email DEST_EMAIL", "Alert destination email") do |e|
    options[:email] = e
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-d", "--detect", "Detect your sound cards") do |d|
    options[:detection] = d
  end
  opts.on("-t", "--test SOUND_CARD_ID", "Test soundcard with the given id") do |t|
    options[:test] = t
  end
  opts.on("-k", "--kill", "Terminating background script") do |k|
    options[:kill] = k
  end
end.parse!

if options[:kill]
  logger.info("Terminating script");
  logger.debug("Looking for pid file in #{PID_FILE}")
  begin
    pidfile = File.open(PID_FILE, "r")
    storedpid = pidfile.read
    Process.kill("TERM", Integer(storedpid))
  rescue Exception => e
    logger.error("Cannot read pid file: " + e.message)
    exit 1
  end
  exit 0
end

if options[:detection]
    puts "Detecting your soundcard..."
    puts `#{HW_DETECTION_CMD}`
    exit 0
end

#Check required binaries
check_required()

if options[:sample]
    SAMPLE_DURATION = options[:sample]
end

if options[:threshold]
    THRESHOLD = options[:threshold].to_f
end

if options[:test]
    puts "Testing soundcard..."
    puts `/usr/bin/arecord -D plughw:#{options[:test]},0 -d #{SAMPLE_DURATION} -f #{FORMAT} 2>/dev/null | /usr/bin/sox -t .wav - -n stat 2>&1`
    exit 0
end

optparse.parse!

#Now raise an exception if we have not found a host option
raise OptionParser::MissingArgument if options[:microphone].nil?
raise OptionParser::MissingArgument if options[:email].nil?

if options[:verbose]
   logger.debug("Script parameters configurations:")
   logger.debug("SoundCard ID: #{options[:microphone]}")
   logger.debug("Sample Duration: #{SAMPLE_DURATION}")
   logger.debug("Output Format: #{FORMAT}")
   logger.debug("Noise Threshold: #{THRESHOLD}")
   logger.debug("Record filename (overwritten): #{RECORD_FILENAME}")
   logger.debug("Destination email: #{options[:email]}")
end

#Starting script part
pid = fork do
  stop_process = false
  Signal.trap("USR1") do
    logger.debug("Running...")
  end
  Signal.trap("TERM") do
    logger.info("Terminating...")
    File.delete(PID_FILE)
    stop_process = true 
  end

  loop do
    if (stop_process)
	logger.info("Noise detector stopped @ #{DateTime.now.strftime('%d/%m/%Y %H:%M:%S')}")	
	break
    end
    rec_out = `/usr/bin/arecord -D plughw:#{options[:microphone]},0 -d #{SAMPLE_DURATION} -f #{FORMAT} -t wav #{RECORD_FILENAME} 2>/dev/null`
    out = `/usr/bin/sox -t .wav #{RECORD_FILENAME} -n stat 2>&1`
    out.match(/Maximum amplitude:\s+(.*)/m)
    amplitude = $1.to_f
    logger.debug("Detected amplitude: #{amplitude}") if options[:verbose]
    if amplitude > THRESHOLD
      logger.info("Sound detected!!!")
  
  	# Read a file
	filecontent = File.open(RECORD_FILENAME ,"rb") {|io| io.read}
 	
        encoded = [filecontent].pack("m")    # base64 econding
puts  value = %x[/usr/sbin/sendmail #{options[:email]} << EOF
subject: WARNING: Noise Detected
from: home@mornati.net
Content-Description: "noise.wav"
Content-Type: audio/x-wav; name="noise.wav"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="noise.wav"
#{encoded}
EOF] 
    else
      logger.debug("No sound detected...")
    end
end
end

Process.detach(pid)
logger.debug("Started... (#{pid})")
File.open(PID_FILE, "w") { |file| file.write(pid) }
