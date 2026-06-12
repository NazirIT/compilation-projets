import sys
from PyQt5.QtWidgets import QApplication
from interface import SGNAnalyzer

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle("Fusion")

    # On laisse le système gérer la palette pour éviter les bugs
    # d'affichage (texte blanc sur fond blanc) dans les boîtes de dialogue (QFileDialog).

    window = SGNAnalyzer()
    window.show()
    sys.exit(app.exec_())