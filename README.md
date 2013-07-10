ruby-noise-detection
====================

Noise Detection Ruby Script

Installation
------------
The noise dector ruby script uses two linux tool to record and analyse de
output: **sox** and **arecord**.
So you need to install these packages on your raspberrypi (or other linux
system):

```bash
sudo apt-get install sox alsa-utils
```

Then, in the current version, the script does not accept parameters to change
file location (log, tmp recording and pid file), so you need to allow the script
execution user (**pi** for example) the write access to these files and folders:

```
RECORD_FILENAME='/tmp/noise.wav'
LOG_FILE='/var/log/noise_detector.log'
PID_FILE='/etc/noised/noised.pid'
```

or you can edit the script changin these variables values with what you prefer
for your system.

Detect Audio Card
-----------------

```bash
pi@raspberrypi ~ $ noise_detection.rb -d
Detecting your soundcard...
 0 [ALSA           ]: BRCM bcm2835 ALSbcm2835 ALSA - bcm2835 ALSA
                      bcm2835 ALSA
 1 [U0x46d0x8d7    ]: USB-Audio - USB Device 0x46d:0x8d7
                      USB Device 0x46d:0x8d7 at usb-bcm2708_usb-1.2, full speed
```

Test Audio Card Record
----------------------
```bash
pi@raspberrypi ~ $ noise_detection.rb -t 1
Testing soundcard...
Samples read:             40000
Length (seconds):      5.000000
Scaled by:         2147483647.0
Maximum amplitude:     0.013245
Minimum amplitude:    -0.041565
Midline amplitude:    -0.014160
Mean    norm:          0.013523
Mean    amplitude:    -0.013466
RMS     amplitude:     0.014662
Maximum delta:         0.023560
Minimum delta:         0.000000
Mean    delta:         0.003664
RMS     delta:         0.004679
Rough   frequency:          406
Volume adjustment:       24.059
```

Starting Noise Detection with Alert
-----------------------------------
```bash
noise_detection.rb -m 1 -n 0.30 -e me@server.com -v
```
The script will be started in background

Terminating Noise Detection
---------------------------
```bash
noise_detection.rb -k
```
