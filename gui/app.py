import sys
from PyQt5.QtWidgets import QApplication
from interface import SGNAnalyzer

# Point d'entrée principal de l'application
if __name__ == "__main__":
    # Initialisation de l'application Qt
    app = QApplication(sys.argv)
    # Application du style Fusion pour un rendu moderne
    app.setStyle("Fusion")
    # Création et affichage de la fenêtre principale
    window = SGNAnalyzer()
    window.show()
    # Lancement de la boucle d'événements
    sys.exit(app.exec_())