# Copyright 2024, The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import hashlib
import logging
import multiprocessing
import os
import pathlib
import signal
import subprocess
import sys
import tempfile
import time


DEFAULT_PROCESS_TERMINATION_TIMEOUT_SECONDS = 1
DEFAULT_MONITOR_INTERVAL_SECONDS = 5
DEFAULT_MEMORY_USAGE_THRESHOLD = 2000
DEFAULT_CPU_USAGE_THRESHOLD = 200
DEFAULT_RESTART_INTERVAL_SECONDS = 60 * 60 * 24
BLOCK_SIGN_FILE = "edit_monitor_block_sign"


def default_daemon_target():
  """Place holder for the default daemon target."""
  print("default daemon target")
  time.sleep(10)


class DaemonManager:
  """Class to manage and monitor the daemon run as a subprocess."""

  def __init__(
      self,
      binary_path: str,
      daemon_target: callable = default_daemon_target,
      daemon_args: tuple = (),
  ):
    self.binary_path = binary_path
    self.daemon_target = daemon_target
    self.daemon_args = daemon_args

    self.pid = os.getpid()
    self.daemon_process = None

    self.max_memory_usage = 0
    self.max_cpu_usage = 0

    pid_file_dir = pathlib.Path(tempfile.gettempdir()).joinpath("edit_monitor")
    pid_file_dir.mkdir(parents=True, exist_ok=True)
    self.pid_file_path = self._get_pid_file_path(pid_file_dir)
    self.block_sign = pathlib.Path(tempfile.gettempdir()).joinpath(
        BLOCK_SIGN_FILE
    )

  def start(self):
    """Writes the pidfile and starts the daemon proces."""
    if self.block_sign.exists():
      logging.warning("Block sign found, exiting...")
      return

    try:
      self._stop_any_existing_instance()
      self._write_pid_to_pidfile()
      self._start_daemon_process()
    except Exception as e:
      logging.exception("Failed to start daemon manager with error %s", e)

  def monitor_daemon(
      self,
      interval: int = DEFAULT_MONITOR_INTERVAL_SECONDS,
      memory_threshold: float = DEFAULT_MEMORY_USAGE_THRESHOLD,
      cpu_threshold: float = DEFAULT_CPU_USAGE_THRESHOLD,
      restart_interval: int = DEFAULT_RESTART_INTERVAL_SECONDS,
  ):
    """Monits the daemon process status.

    Periodically check the CPU/Memory usage of the daemon process as long as the
    process is still running and kill the process if the resource usage is above
    given thresholds.
    """
    if not self.daemon_process:
      return

    logging.info("start monitoring daemon process %d.", self.daemon_process.pid)
    restart_time = time.time() + restart_interval
    while self.daemon_process.is_alive():
      if time.time() > restart_time:
        self.restart()
      try:
        memory_usage = self._get_process_memory_percent(self.daemon_process.pid)
        self.max_memory_usage = max(self.max_memory_usage, memory_usage)

        cpu_usage = self._get_process_cpu_percent(self.daemon_process.pid)
        self.max_cpu_usage = max(self.max_cpu_usage, cpu_usage)

        time.sleep(interval)
      except Exception as e:
        # Logging the error and continue.
        logging.warning("Failed to monitor daemon process with error: %s", e)

      if (
          self.max_memory_usage >= memory_threshold
          or self.max_cpu_usage >= cpu_threshold
      ):
        logging.error(
            "Daemon process is consuming too much resource, killing..."
        ),
        self._terminate_process(self.daemon_process.pid)

    logging.info(
        "Daemon process %d terminated. Max memory usage: %f, Max cpu"
        " usage: %f.",
        self.daemon_process.pid,
        self.max_memory_usage,
        self.max_cpu_usage,
    )

  def stop(self):
    """Stops the daemon process and removes the pidfile."""

    logging.debug("in daemon manager cleanup.")
    try:
      if self.daemon_process and self.daemon_process.is_alive():
        self._terminate_process(self.daemon_process.pid)
      self._remove_pidfile()
      logging.debug("Successfully stopped daemon manager.")
    except Exception as e:
      logging.exception("Failed to stop daemon manager with error %s", e)

  def restart(self):
    """Restarts the current process.

    Stops the current daemon manager and restarts the entire process based on
    the binary file. Exits directly If the binary file no longer exists.
    """
    logging.debug("Restarting process based on binary %s.", self.binary_path)

    # Stop the current daemon manager first.
    self.stop()

    # If the binary no longer exists, exit directly.
    if not os.path.exists(self.binary_path):
      logging.info("binary %s no longer exists, exiting.", self.binary_path)
      sys.exit(0)

    try:
      os.execv(self.binary_path, sys.argv)
    except OSError as e:
      logging.exception("Failed to restart process with error: %s.", e)
      sys.exit(1)  # Indicate an error occurred

  def cleanup(self):
    """Wipes out all edit monitor instances in the system.

    Stops all the existing edit monitor instances and place a block sign
    to prevent any edit monitor process to start. This method is only used
    in emergency case when there's something goes wrong with the edit monitor
    that requires immediate cleanup to prevent damanger to the system.
    """
    logging.debug("Start cleaning up all existing instances.")

    try:
      # First places a block sign to prevent any edit monitor process to start.
      self.block_sign.touch()
    except (FileNotFoundError, PermissionError, OSError):
      logging.exception("Failed to place the block sign")

    # Finds and kills all the existing instances of edit monitor.
    existing_instances_pids = self._find_all_instances_pids()
    for pid in existing_instances_pids:
      logging.info(
          "Found existing edit monitor instance with pid %d, killing...", pid
      )
      try:
        self._terminate_process(pid)
      except Exception:
        logging.exception("Failed to terminate process %d", pid)

  def _stop_any_existing_instance(self):
    if not self.pid_file_path.exists():
      logging.debug("No existing instances.")
      return

    ex_pid = self._read_pid_from_pidfile()

    if ex_pid:
      logging.info("Found another instance with pid %d.", ex_pid)
      self._terminate_process(ex_pid)
      self._remove_pidfile()

  def _read_pid_from_pidfile(self):
    with open(self.pid_file_path, "r") as f:
      return int(f.read().strip())

  def _write_pid_to_pidfile(self):
    """Creates a pidfile and writes the current pid to the file.

    Raise FileExistsError if the pidfile already exists.
    """
    try:
      # Use the 'x' mode to open the file for exclusive creation
      with open(self.pid_file_path, "x") as f:
        f.write(f"{self.pid}")
    except FileExistsError as e:
      # This could be caused due to race condition that a user is trying
      # to start two edit monitors at the same time. Or because there is
      # already an existing edit monitor running and we can not kill it
      # for some reason.
      logging.exception("pidfile %s already exists.", self.pid_file_path)
      raise e

  def _start_daemon_process(self):
    """Starts a subprocess to run the daemon."""
    p = multiprocessing.Process(
        target=self.daemon_target, args=self.daemon_args
    )
    p.start()

    logging.info("Start subprocess with PID %d", p.pid)
    self.daemon_process = p

  def _terminate_process(
      self, pid: int, timeout: int = DEFAULT_PROCESS_TERMINATION_TIMEOUT_SECONDS
  ):
    """Terminates a process with given pid.

    It first sends a SIGTERM to the process to allow it for proper
    termination with a timeout. If the process is not terminated within
    the timeout, kills it forcefully.
    """
    try:
      os.kill(pid, signal.SIGTERM)
      if not self._wait_for_process_terminate(pid, timeout):
        logging.warning(
            "Process %d not terminated within timeout, try force kill", pid
        )
        os.kill(pid, signal.SIGKILL)
    except ProcessLookupError:
      logging.info("Process with PID %d not found (already terminated)", pid)

  def _wait_for_process_terminate(self, pid: int, timeout: int) -> bool:
    start_time = time.time()

    while time.time() < start_time + timeout:
      if not self._is_process_alive(pid):
        return True
      time.sleep(1)

    logging.error("Process %d not terminated within %d seconds.", pid, timeout)
    return False

  def _is_process_alive(self, pid: int) -> bool:
    try:
      output = subprocess.check_output(
          ["ps", "-p", str(pid), "-o", "state="], text=True
      ).strip()
      state = output.split()[0]
      return state != "Z"  # Check if the state is not 'Z' (zombie)
    except subprocess.CalledProcessError:
      # Process not found (already dead).
      return False
    except (FileNotFoundError, OSError, ValueError) as e:
      logging.warning(
          "Unable to check the status for process %d with error: %s.", pid, e
      )
      return True

  def _remove_pidfile(self):
    try:
      os.remove(self.pid_file_path)
    except FileNotFoundError:
      logging.info("pid file %s already removed.", self.pid_file_path)

  def _get_pid_file_path(self, pid_file_dir: pathlib.Path) -> pathlib.Path:
    """Generates the path to store the pidfile.

    The file path should have the format of "/tmp/edit_monitor/xxxx.lock"
    where xxxx is a hashed value based on the binary path that starts the
    process.
    """
    hash_object = hashlib.sha256()
    hash_object.update(self.binary_path.encode("utf-8"))
    pid_file_path = pid_file_dir.joinpath(hash_object.hexdigest() + ".lock")
    logging.info("pid_file_path: %s", pid_file_path)

    return pid_file_path

  def _get_process_memory_percent(self, pid: int) -> float:
    try:
      with open(f"/proc/{pid}/stat", "r") as f:
        stat_data = f.readline().split()
        # RSS is the 24th field in /proc/[pid]/stat
        rss_pages = int(stat_data[23])
        return rss_pages * 4 / 1024  # Covert to MB
    except (FileNotFoundError, IndexError, ValueError, IOError) as e:
      logging.exception("Failed to get memory usage.")
      raise e

  def _get_process_cpu_percent(self, pid: int, interval: int = 1) -> float:
    try:
      total_start_time = self._get_total_cpu_time(pid)
      with open("/proc/uptime", "r") as f:
        uptime_start = float(f.readline().split()[0])

      time.sleep(interval)

      total_end_time = self._get_total_cpu_time(pid)
      with open("/proc/uptime", "r") as f:
        uptime_end = float(f.readline().split()[0])

      return (
          (total_end_time - total_start_time)
          / (uptime_end - uptime_start)
          * 100
      )
    except (FileNotFoundError, IndexError, ValueError, IOError) as e:
      logging.exception("Failed to get CPU usage.")
      raise e

  def _get_total_cpu_time(self, pid: int) -> float:
    with open(f"/proc/{str(pid)}/stat", "r") as f:
      stats = f.readline().split()
      # utime is the 14th field in /proc/[pid]/stat measured in clock ticks.
      utime = int(stats[13])
      # stime is the 15th field in /proc/[pid]/stat measured in clock ticks.
      stime = int(stats[14])
      return (utime + stime) / os.sysconf(os.sysconf_names["SC_CLK_TCK"])

  def _find_all_instances_pids(self) -> list[int]:
    pids = []

    for file in os.listdir(self.pid_file_path.parent):
      if file.endswith(".lock"):
        try:
          with open(self.pid_file_path.parent.joinpath(file), "r") as f:
            pids.append(int(f.read().strip()))
        except (FileNotFoundError, IOError, ValueError, TypeError):
          logging.exception("Failed to get pid from file path: %s", file)

    return pids