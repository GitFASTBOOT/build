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


import getpass
import logging
import os
import pathlib
import platform
import time
from atest.metrics import clearcut_client
from atest.proto import clientanalytics_pb2
from proto import edit_event_pb2
from watchdog.events import FileSystemEvent
from watchdog.events import PatternMatchingEventHandler
from watchdog.observers import Observer


LOG_SOURCE = 2395


class ClearcutEventHandler(PatternMatchingEventHandler):

  def __init__(self, path, cclient=None):

    super().__init__(patterns=["*"], ignore_directories=True)
    self.root_monitoring_path = path
    self.cclient = (
        clearcut_client.Clearcut(LOG_SOURCE) if not cclient else cclient
    )

    self.user_name = getpass.getuser()
    self.host_name = platform.node()
    self.source_root = os.environ.get("ANDROID_BUILD_TOP", "")

  def on_moved(self, event: FileSystemEvent):
    self._log_edit_event(event, edit_event_pb2.EditEvent.MOVE)

  def on_created(self, event: FileSystemEvent):
    self._log_edit_event(event, edit_event_pb2.EditEvent.CREATE)

  def on_deleted(self, event: FileSystemEvent):
    self._log_edit_event(event, edit_event_pb2.EditEvent.DELETE)

  def on_modified(self, event: FileSystemEvent):
    self._log_edit_event(event, edit_event_pb2.EditEvent.MODIFY)

  def flushall(self):
    logging.info("flushing all pending events.")
    self.cclient.flush_events()

  def _log_edit_event(
      self, event: FileSystemEvent, edit_type: edit_event_pb2.EditEvent.EditType
  ):
    try:
      event_time = time.time()

      if self._is_hidden_file(pathlib.Path(event.src_path)):
        logging.debug("ignore hidden file: %s.", event.src_path)
        return

      if not self._is_under_git_project(pathlib.Path(event.src_path)):
        logging.debug(
            "ignore file %s which does not belong to a git project",
            event.src_path,
        )
        return

      logging.info("%s: %s", event.event_type, event.src_path)

      event_proto = edit_event_pb2.EditEvent(
          user_name=self.user_name,
          host_name=self.host_name,
          source_root=self.source_root,
      )
      event_proto.single_edit_event.CopyFrom(
          edit_event_pb2.EditEvent.SingleEditEvent(
              file_path=event.src_path, edit_type=edit_type
          )
      )
      clearcut_log_event = clientanalytics_pb2.LogEvent(
          event_time_ms=int(event_time * 1000),
          source_extension=event_proto.SerializeToString(),
      )

      self.cclient.log(clearcut_log_event)
    except Exception:
      logging.exception("Failed to log edit event.")

  def _is_hidden_file(self, file_path: pathlib.Path) -> bool:
    # Check if the file itself is hidden
    if file_path.name.startswith("."):
      return True

    current_dir = file_path.parent
    while True:
      if current_dir.name.startswith("."):
        return True
      if str(current_dir.resolve()) == self.root_monitoring_path:
        break
      current_dir = current_dir.parent

    return False

  def _is_under_git_project(self, file_path: pathlib.Path) -> bool:
    current_dir = file_path.parent
    while True:
      if current_dir.joinpath(".git").exists():
        return True
      # All files should be under the root monitoring path
      if str(current_dir.resolve()) == self.root_monitoring_path:
        break
      current_dir = current_dir.parent

    return False


def start_edit_monitor(path, cclient: clearcut_client.Clearcut = None):
  event_handler = ClearcutEventHandler(path, cclient)
  observer = Observer()

  logging.info("Starting observer on path %s.", path)
  observer.schedule(event_handler, path, recursive=True)
  observer.start()
  logging.info("Observer started")

  try:
    while True:
      time.sleep(1)
  finally:
    event_handler.flushall()
    observer.stop()
    observer.join()
