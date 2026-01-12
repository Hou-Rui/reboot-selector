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
    errorOccurred = Signal(str)
    successOccurred = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._entries = []
        self.reload()

    # ---------- helpers ----------

    def _run_bootctl(self, args, require_root=False):
        cmd = ["bootctl"] + args
        if require_root and os.geteuid() != 0:
            cmd = ["pkexec"] + cmd
        return subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

    # ---------- properties ----------

    @Property("QVariantList", notify=entriesChanged)
    def entries(self):
        return self._entries

    @Property("QVariant", notify=entriesChanged)
    def defaultEntry(self):
        for entry in self._entries:
            if entry['isDefault']:
                return entry
        return None

    # ---------- slots ----------

    @Slot()
    def reload(self):
        result = self._run_bootctl(["list", "--json=short"])
        if result.returncode != 0:
            self.errorOccurred.emit(result.stderr.strip())
            return
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError as e:
            self.errorOccurred.emit(str(e))
            return
        entries = []
        for e in data:
            if not e.get("id"):
                continue
            entries.append({
                "id": e["id"],
                "title": e.get("showTitle") or e.get("title") or e["id"],
                "isDefault": bool(e.get("isDefault")),
                "isSelected": bool(e.get("isSelected")),
                "type": e.get("type"),
            })
        self._entries = entries
        self.entriesChanged.emit()

    @Slot(str)
    def setOneShot(self, entry_id):
        result = self._run_bootctl(
            ["set-oneshot", entry_id], require_root=True)
        if result.returncode != 0:
            self.errorOccurred.emit(result.stderr.strip())
        else:
            self.successOccurred.emit(f"Next boot entry updated.")
        self.reload()
