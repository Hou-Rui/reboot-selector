#!/usr/bin/env python3
import sys
from pathlib import Path
from signal import SIG_DFL, SIGINT, signal

from PySide6.QtCore import QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

import backend

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName("reboot-selector")
    app.setDesktopFileName("reboot-selector")
    app.setApplicationDisplayName("Reboot Selector")
    signal(SIGINT, SIG_DFL)
    engine = QQmlApplicationEngine()
    qml_file = Path(__file__).parent / "main.qml"
    engine.load(QUrl.fromLocalFile(qml_file))
    if not engine.rootObjects():
        sys.exit(-1)
    exit_code = app.exec()
    del engine
    sys.exit(exit_code)
