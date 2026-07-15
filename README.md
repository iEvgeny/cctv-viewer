[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


# CCTV Viewer

CCTV Viewer - a simple application for simultaneously viewing multiple video streams. Designed for high performance and low latency.
Based on ffmpeg.

To clone this repository be sure to use the following command:

	git clone --recurse-submodules https://github.com/jahedcuet/cctv-viewer.git

## Features

* Simultaneous viewing of multiple video streams in a customizable grid.
* **ONVIF support** — add an ONVIF camera or an NVR/DVR by IP address. NVRs/DVRs
  expose many channels behind a single IP; every channel is detected and can be
  added individually. Devices can be auto-discovered on the local network
  (WS-Discovery) or by scanning any subnet/IP range (unicast) for remote add.
* **Manual RTSP entry** with separate **main-stream** and **sub-stream** URL
  fields per viewport.
* **Auto adapting resolution** — the low-resolution sub stream is used in the
  grid view and the application automatically switches to the high-resolution
  main stream when a viewport is maximized (full screen or single 1×1 view).
* **Audio** from cameras and NVR channels, with a mute toggle and a volume
  slider available on every audio-capable channel (both on-screen, on hover,
  and in the sidebar). A **master mute** button (Ctrl+M) silences everything,
  and a speaker badge highlights which viewport is currently generating sound.
* **Batch import / export** of all presets and sources to a single JSON file.
* Presets, geometry/aspect-ratio control, cell merging, kiosk mode and more.

### Adding an ONVIF camera or NVR/DVR

1. Open the sidebar and expand **Sources → ONVIF → Add camera / NVR…**.
2. Either press **Discover** to scan the local network, enter a **Subnet**
   (e.g. `192.168.1.0/24` or `10.0.0.1-10.0.0.50`) and press **Scan subnet**
   to find devices on a remote/routed network, or type the device **host/IP**,
   **port** and **credentials** and press **Connect**.
3. The detected channels are listed with their main/sub stream resolutions.
   Select the ones you want and press **Add selected to layout** — they fill the
   free viewports of the current preset.

### Batch import / export

Use **Sources → Batch → Export…** to save every preset and its sources to a
JSON file, and **Import…** to restore them on another machine.

## Installing on Debian / Ubuntu (without snap)

Two script-based options are provided for installing from source without snap.

### Option A — build and install directly

```sh
git clone --recurse-submodules https://github.com/jahedcuet/cctv-viewer.git
cd cctv-viewer
./install-debian.sh
```

This installs the build/runtime dependencies, builds the application with CMake
and installs it into `/usr`. To remove it later run `./install-debian.sh --uninstall`.

### Option B — build a .deb package

```sh
cd cctv-viewer
./make-deb.sh
sudo apt install ../cctv-viewer_*.deb
```

Both scripts require `sudo` privileges to install packages.
