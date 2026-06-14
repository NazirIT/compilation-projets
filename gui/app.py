import sys
from PyQt5.QtWidgets import QApplication
from interface import SGNAnalyzer

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = SGNAnalyzer()
    window.show()
    sys.exit(app.exec_())