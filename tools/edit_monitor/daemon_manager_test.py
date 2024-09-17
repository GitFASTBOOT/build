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

"""Unittests for DaemonManager."""

import logging
import multiprocessing
import os
import pathlib
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock
from edit_monitor import daemon_manager

TEST_BINARY_FILE = '/path/to/test_binary'
TEST_PID_FILE_PATH = (
    '587239c2d1050afdf54512e2d799f3b929f86b43575eb3c7b4bab105dd9bd25e.lock'
)


def example_daemon(output_file):
  with open(output_file, 'w') as f:
    f.write('running daemon target')


def long_running_daemon():
  while True:
    time.sleep(1)


class DaemonManagerTest(unittest.TestCase):

  @classmethod
  def setUpClass(cls):
    super().setUpClass()
    # Configure to print logging to stdout.
    logging.basicConfig(filename=None, level=logging.DEBUG)
    console = logging.StreamHandler(sys.stdout)
    logging.getLogger('').addHandler(console)

  def setUp(self):
    super().setUp()
    self.original_tempdir = tempfile.tempdir
    self.working_dir = tempfile.TemporaryDirectory()
    # Sets the tempdir under the working dir so any temp files created during
    # tests will be cleaned.
    tempfile.tempdir = self.working_dir.name

  def tearDown(self):
    # Cleans up any child processes left by the tests.
    self._cleanup_child_processes()
    self.working_dir.cleanup()
    # Restores tempdir.
    tempfile.tempdir = self.original_tempdir
    super().tearDown()

  def test_start_success(self):
    damone_output_file = tempfile.NamedTemporaryFile(
        dir=self.working_dir.name, delete=False
    )
    dm = daemon_manager.DaemonManager(
        TEST_BINARY_FILE,
        daemon_target=example_daemon,
        daemon_args=(damone_output_file.name,),
    )
    dm.start()
    dm.daemon_process.join()

    # Verifies the expected pid file is created.
    expected_pid_file_path = pathlib.Path(self.working_dir.name).joinpath(
        'edit_monitor', TEST_PID_FILE_PATH
    )
    self.assertEqual(dm.pid_file_path, expected_pid_file_path)
    self.assertTrue(expected_pid_file_path.exists())

    # Verifies the daemon process is executed successfully.
    with open(damone_output_file.name, 'r') as f:
      contents = f.read()
      self.assertEqual(contents, 'running daemon target')

  def test_start_success_with_existing_instance(self):
    p = multiprocessing.Process(target=long_running_daemon)
    p.start()

    # Create a pidfile with the subprocess pid
    pid_file_path_dir = pathlib.Path(self.working_dir.name).joinpath(
        'edit_monitor'
    )
    pid_file_path_dir.mkdir(parents=True, exist_ok=True)
    with open(pid_file_path_dir.joinpath(TEST_PID_FILE_PATH), 'w') as f:
      f.write(str(p.pid))

    damone_output_file = tempfile.NamedTemporaryFile(
        dir=self.working_dir.name, delete=False
    )
    dm = daemon_manager.DaemonManager(
        TEST_BINARY_FILE,
        daemon_target=example_daemon,
        daemon_args=(damone_output_file.name,),
    )
    dm.start()
    dm.daemon_process.join()

    # Verify the daemon process is executed successfully.
    with open(damone_output_file.name, 'r') as f:
      contents = f.read()
      self.assertEqual(contents, 'running daemon target')

  def test_start_success_with_existing_instance_already_dead(self):
    # Create a pidfile with pid that does not exist.
    pid_file_path_dir = pathlib.Path(self.working_dir.name).joinpath(
        'edit_monitor'
    )
    pid_file_path_dir.mkdir(parents=True, exist_ok=True)
    with open(pid_file_path_dir.joinpath(TEST_PID_FILE_PATH), 'w') as f:
      f.write('123456')

    damone_output_file = tempfile.NamedTemporaryFile(
        dir=self.working_dir.name, delete=False
    )
    dm = daemon_manager.DaemonManager(
        TEST_BINARY_FILE,
        daemon_target=example_daemon,
        daemon_args=(damone_output_file.name,),
    )
    dm.start()
    dm.daemon_process.join()

    # Verify the daemon process is executed successfully.
    with open(damone_output_file.name, 'r') as f:
      contents = f.read()
      self.assertEqual(contents, 'running daemon target')

  @mock.patch('os.kill')
  def test_start_failed_to_kill_existing_instance(self, mock_kill):
    mock_kill.side_effect = OSError('Unknown OSError')
    pid_file_path_dir = pathlib.Path(self.working_dir.name).joinpath(
        'edit_monitor'
    )
    pid_file_path_dir.mkdir(parents=True, exist_ok=True)
    with open(pid_file_path_dir.joinpath(TEST_PID_FILE_PATH), 'w') as f:
      f.write('123456')

    dm = daemon_manager.DaemonManager(TEST_BINARY_FILE)
    dm.start()

    # Verify no daemon process is started.
    self.assertIsNone(dm.daemon_process)

  def test_start_failed_to_write_pidfile(self):
    pid_file_path_dir = pathlib.Path(self.working_dir.name).joinpath(
        'edit_monitor'
    )
    pid_file_path_dir.mkdir(parents=True, exist_ok=True)
    # Makes the directory read-only so write pidfile will fail.
    os.chmod(pid_file_path_dir, 0o555)

    dm = daemon_manager.DaemonManager(TEST_BINARY_FILE)
    dm.start()

    # Verifies no daemon process is started.
    self.assertIsNone(dm.daemon_process)

  def test_start_failed_to_start_daemon_process(self):
    dm = daemon_manager.DaemonManager(
        TEST_BINARY_FILE, daemon_target='wrong_target', daemon_args=(1)
    )
    dm.start()

    # Verifies no daemon process is started.
    self.assertIsNone(dm.daemon_process)

  def test_stop_success(self):
    dm = daemon_manager.DaemonManager(
        TEST_BINARY_FILE, daemon_target=long_running_daemon
    )
    dm.start()
    dm.stop()

    self.assert_no_subprocess_running()
    self.assertFalse(dm.pid_file_path.exists())

  @mock.patch('os.kill')
  def test_stop_failed_to_kill_daemon_process(self, mock_kill):
    mock_kill.side_effect = OSError('Unknown OSError')
    dm = daemon_manager.DaemonManager(
        TEST_BINARY_FILE, daemon_target=long_running_daemon
    )
    dm.start()
    dm.stop()

    self.assertTrue(dm.daemon_process.is_alive())
    self.assertTrue(dm.pid_file_path.exists())

  @mock.patch('os.remove')
  def test_stop_failed_to_remove_pidfile(self, mock_remove):
    mock_remove.side_effect = OSError('Unknown OSError')

    dm = daemon_manager.DaemonManager(
        TEST_BINARY_FILE, daemon_target=long_running_daemon
    )
    dm.start()
    dm.stop()

    self.assert_no_subprocess_running()
    self.assertTrue(dm.pid_file_path.exists())

  def assert_no_subprocess_running(self):
    child_pids = self._get_child_processes(os.getpid())
    for child_pid in child_pids:
      self.assertFalse(
          self._is_process_alive(child_pid), f'process {child_pid} still alive'
      )

  def _get_child_processes(self, parent_pid):
    try:
      output = subprocess.check_output(
          ['ps', '-o', 'pid,ppid', '--no-headers'], text=True
      )

      child_processes = []
      for line in output.splitlines():
        pid, ppid = line.split()
        if int(ppid) == parent_pid:
          child_processes.append(int(pid))
      return child_processes
    except subprocess.CalledProcessError as e:
      self.fail(f'failed to get child process, error: {e}')

  def _is_process_alive(self, pid):
    try:
      output = (
          subprocess.check_output(
              ['ps', '-p', str(pid), '-o', 'state='], stderr=subprocess.STDOUT
          )
          .decode()
          .strip()
      )
      state = output.split()[0]
      return state != 'Z'  # Check if the state is not 'Z' (zombie)
    except subprocess.CalledProcessError:
      return False

  def _cleanup_child_processes(self):
    child_pids = self._get_child_processes(os.getpid())
    for child_pid in child_pids:
      try:
        os.kill(child_pid, signal.SIGKILL)
      except ProcessLookupError:
        # process already terminated
        pass


if __name__ == '__main__':
  unittest.main()
