#!/usr/bin/env python3
import json
import os
import subprocess

from PySide6.QtCore import Property, QObject, Signal, Slot
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "Backend"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class BootModel(QObject):
    entriesChanged = Signal()
    messageChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._entries = []
        self._message = {"type": "", "text": ""}
        self.reload()

    # ---------- helpers ----------
    def _set_message(self, type: str, text: str):
        self._message = {"type": type, "text": text}
        self.messageChanged.emit()

    def _run(self, args: list[str], root: bool = False) -> str:
        if root and os.geteuid() != 0:
            args = ["pkexec"] + args
        result = subprocess.run(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip())
        return result.stdout.strip()

    # ---------- properties ----------

    @Property("QVariantList", notify=entriesChanged)  # type: ignore
    def entries(self):
        return self._entries

    @Property("QVariant", notify=entriesChanged)  # type: ignore
    def defaultEntry(self):
        for entry in self._entries:
            if entry["isDefault"]:
                return entry
        return None

    @Property("QVariant", notify=messageChanged)  # type: ignore
    def message(self):
        return self._message

    # ---------- slots ----------

    @Slot()
    def reload(self):
        self._set_message("", "")
        self._entries = []
        try:
            result = self._run(["bootctl", "list", "--json=short"])
            self._entries = [
                {
                    "id": e["id"],
                    "title": e.get("showTitle") or e.get("title") or e["id"],
                    "isDefault": bool(e.get("isDefault")),
                    "isSelected": bool(e.get("isSelected")),
                    "type": e.get("type"),
                }
                for e in json.loads(result)
                if "id" in e
            ]
            self.entriesChanged.emit()
        except (json.JSONDecodeError, RuntimeError) as err:
            self._set_message("error", str(err))

    @Slot(str)
    def setOneShot(self, entry_id: str):
        try:
            self._run(["bootctl", "set-oneshot", entry_id], root=True)
            self.reload()
            self._set_message("positive", self.tr("Next boot entry updated."))
        except RuntimeError as err:
            self._set_message("error", str(err))

    @Slot()
    def rebootNow(self):
        try:
            self._run(["systemctl", "reboot"])
        except RuntimeError as err:
            self._set_message("error", str(err))
