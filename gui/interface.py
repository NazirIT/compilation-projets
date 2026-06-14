

import sys
import os
import csv
from parser_bridge import run_parser

from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QHBoxLayout, QVBoxLayout,
    QPushButton, QLabel, QTableWidget, QTableWidgetItem, QHeaderView,
    QFrame, QSizePolicy, QSpacerItem, QFileDialog, QMessageBox
)
from PyQt5.QtGui import (
    QFont, QColor, QPalette, QSyntaxHighlighter, QTextCharFormat,
    QFontDatabase, QIcon, QPainter, QBrush
)
from PyQt5.QtCore import Qt, QRegExp, QSize
from PyQt5.QtWidgets import QTextEdit



#  SYNTAX HIGHLIGHTER pour l'éditeur SGN

class SGNHighlighter(QSyntaxHighlighter):
    """
    Classe permettant de gérer la coloration syntaxique du code SGN 
    dans la zone d'édition en fonction d'expressions régulières.
    """
    def __init__(self, document):
        super().__init__(document)
        self.rules = []

        def add_rule(pattern, color, bold=False, italic=False):
            fmt = QTextCharFormat()
            fmt.setForeground(QColor(color))
            if bold:
                fmt.setFontWeight(QFont.Bold)
            if italic:
                fmt.setFontItalic(True)
            self.rules.append((QRegExp(pattern), fmt))

        # Commentaires (SGN utilise --)
        add_rule(r'--[^\n]*',           '#5c6a8a', italic=True)
        # Mots-clés principaux
        add_rule(r'\b(ANNEE|NIVEAU|ETUDIANT|SEMESTRE|MODULE|COEF|NOTE|MATRICULE|NOM|PRENOM)\b', '#c678dd', bold=True)
        # Niveaux et Semestres
        add_rule(r'\b(L[1-3]|S[1-6])\b', '#61aeee', bold=True)
        # Strings
        add_rule(r'"[^"]*"',            '#98c379')
        add_rule(r"'[^']*'",            '#98c379')
        # Nombres
        add_rule(r'\b[0-9]+\.?[0-9]*\b', '#d19a66')
        # Accolades / crochets
        add_rule(r'[{}[\]]',            '#abb2bf')

    def highlightBlock(self, text):
        for pattern, fmt in self.rules:
            idx = pattern.indexIn(text)
            while idx >= 0:
                length = pattern.matchedLength()
                self.setFormat(idx, length, fmt)
                idx = pattern.indexIn(text, idx + length)



#  WIDGET : Éditeur de code (panneau gauche)

class CodeEditor(QWidget):
    def __init__(self):
        super().__init__()
        self._build_ui()

    def _build_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # ── Barre de titre de l'éditeur ──
        header = QWidget()
        header.setFixedHeight(40)
        header.setStyleSheet("background:#252a3a; border-top-left-radius:10px; border-top-right-radius:10px;")
        h_layout = QHBoxLayout(header)
        h_layout.setContentsMargins(14, 0, 14, 0)

        # icône <>
        icon_lbl = QLabel("<>")
        icon_lbl.setFont(QFont("Consolas", 10))
        icon_lbl.setStyleSheet("color:#8899bb;")
        h_layout.addWidget(icon_lbl)

        # nom fichier
        self.fname_label = QLabel("nouveau_fichier.sgn")
        self.fname_label.setFont(QFont("Consolas", 11))
        self.fname_label.setStyleSheet("color:#b0bdd8; margin-left:6px;")
        h_layout.addWidget(self.fname_label)
        h_layout.addStretch()

        # 3 points rouge / jaune / vert
        for color in ("#ff5f57", "#febc2e", "#28c840"):
            dot = QLabel("●")
            dot.setFont(QFont("Arial", 13))
            dot.setStyleSheet(f"color:{color};")
            h_layout.addWidget(dot)

        layout.addWidget(header)

        # ── Zone de code ──
        self.editor = QTextEdit()
        self.editor.setReadOnly(False)
        self.editor.setStyleSheet("""
            QTextEdit {
                background-color: #1a1e2e;
                color: #c8d0e8;
                border: none;
                border-bottom-left-radius: 10px;
                border-bottom-right-radius: 10px;
                padding: 12px 10px;
                selection-background-color: #3a4460;
            }
        """)
        mono = QFont("Consolas", 12)
        mono.setStyleHint(QFont.Monospace)
        self.editor.setFont(mono)

        code = "-- Nouveau fichier notes SGN\n\n"
        self.editor.setPlainText(code)
        self.highlighter = SGNHighlighter(self.editor.document())

        layout.addWidget(self.editor)

    def set_filename(self, name):
        self.fname_label.setText(name)

    def get_code(self):
        return self.editor.toPlainText()

    def set_code(self, code):
        self.editor.setPlainText(code)


#  WIDGET : Console Logs

class ConsolePanel(QWidget):
    def __init__(self):
        super().__init__()
        self._build_ui()

    def _build_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        self.setStyleSheet("""
            QWidget {
                background: #ffffff;
                border: 1px solid #e0e3e8;
                border-radius: 10px;
            }
        """)

        # ── Header ──
        header = QWidget()
        header.setFixedHeight(42)
        header.setStyleSheet("""
            QWidget {
                background: #fafbfc;
                border-bottom: 1px solid #e8eaee;
                border-top-left-radius: 10px;
                border-top-right-radius: 10px;
                border-bottom-left-radius: 0px;
                border-bottom-right-radius: 0px;
            }
        """)
        hl = QHBoxLayout(header)
        hl.setContentsMargins(16, 0, 16, 0)

        title = QLabel("CONSOLE LOGS")
        title.setFont(QFont("Segoe UI", 9, QFont.Bold))
        title.setStyleSheet("color:#555; letter-spacing:1px; border:none; background:transparent;")
        hl.addWidget(title)
        layout.addWidget(header)

        # ── Logs body ──
        self.body = QWidget()
        self.body.setStyleSheet("background:#fff; border:none; border-bottom-left-radius:10px; border-bottom-right-radius:10px;")
        self.bl = QVBoxLayout(self.body)
        self.bl.setContentsMargins(16, 14, 16, 14)
        self.bl.setSpacing(4)
        self.bl.setAlignment(Qt.AlignTop)

        layout.addWidget(self.body)
        self.display_logs([])

    def display_logs(self, erreurs):
        # Nettoyer les anciens logs
        while self.bl.count():
            child = self.bl.takeAt(0)
            if child.widget():
                child.widget().deleteLater()
                
        if not erreurs:
            success = QLabel("  Analyse réussie. Aucune erreur.")
            success.setFont(QFont("Segoe UI", 11, QFont.Bold))
            success.setStyleSheet("color:#22a855; margin-top:6px; border:none; background:transparent;")
            self.bl.addWidget(success)
        else:
            mono = QFont("Consolas", 11)
            for err in erreurs:
                lbl = QLabel("❌" + err)
                lbl.setFont(mono)
                lbl.setStyleSheet("color:#e05252; border:none; background:transparent;")
                lbl.setWordWrap(True)
                self.bl.addWidget(lbl)



#  WIDGET : Tableau de résultats

class ResultsPanel(QWidget):
    def __init__(self):
        super().__init__()
        self._build_ui()

    def _build_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        self.setStyleSheet("""
            QWidget#resultsPanel {
                background: #ffffff;
                border: 1px solid #e0e3e8;
                border-radius: 10px;
            }
        """)
        self.setObjectName("resultsPanel")

        # ── Header ──
        header = QWidget()
        header.setFixedHeight(48)
        header.setStyleSheet("""
            QWidget {
                background: #fafbfc;
                border-bottom: 1px solid #e8eaee;
                border-top-left-radius: 10px;
                border-top-right-radius: 10px;
                border-bottom-left-radius: 0;
                border-bottom-right-radius: 0;
            }
        """)
        hl = QHBoxLayout(header)
        hl.setContentsMargins(16, 0, 16, 0)

        title = QLabel("RÉSULTATS DE COMPILATION")
        title.setFont(QFont("Segoe UI", 9, QFont.Bold))
        title.setStyleSheet("color:#555; letter-spacing:1px; border:none; background:transparent;")
        hl.addWidget(title)
        hl.addStretch()
        layout.addWidget(header)

        # ── Table ──
        self.table = QTableWidget()
        self.table.setStyleSheet("""
            QTableWidget {
                background: #ffffff;
                border: none;
                border-bottom-left-radius: 10px;
                border-bottom-right-radius: 10px;
                gridline-color: #f0f2f5;
                outline: none;
            }
            QTableWidget::item {
                padding: 10px 14px;
                border-bottom: 1px solid #f0f2f5;
                color: #222;
            }
            QTableWidget::item:selected {
                background: #eef4ff;
                color: #222;
            }
            QHeaderView::section {
                background: #fafbfc;
                color: #777;
                font-size: 11px;
                font-weight: bold;
                padding: 10px 14px;
                border: none;
                border-bottom: 2px solid #e8eaee;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
        """)
        self.table.setFont(QFont("Segoe UI", 12))
        self.table.verticalHeader().setVisible(False)
        self.table.setSelectionBehavior(QTableWidget.SelectRows)
        self.table.setEditTriggers(QTableWidget.NoEditTriggers)
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.setShowGrid(False)
        self.table.setAlternatingRowColors(False)
        self.table.verticalHeader().setMinimumSectionSize(52)
        self.table.verticalHeader().setSectionResizeMode(QHeaderView.ResizeToContents)

        columns = ["Matricule", "Nom & Prénom", "Niveau",
                   "Moy. Semestre(s)", "Moy. Annuelle", "Rang", "Mention", "Décision"]
        self.table.setColumnCount(len(columns))
        self.table.setHorizontalHeaderLabels(columns)
        self.table.setRowCount(0)

        # Largeurs colonnes
        self.table.setColumnWidth(0, 180)
        self.table.setColumnWidth(1, 150)
        self.table.setColumnWidth(2, 70)
        self.table.setColumnWidth(3, 200)
        self.table.setColumnWidth(4, 120)
        self.table.setColumnWidth(5, 60)
        self.table.setColumnWidth(6, 180)
        self.table.setColumnWidth(7, 80)

        layout.addWidget(self.table)

    def populate_table(self, data_list):
        self.table.setRowCount(len(data_list))
        for row, item in enumerate(data_list):
            self.table.setItem(row, 0, self._cell(item.get("Matricule", "")))

            # Nom et prénom
            nom_widget = QWidget()
            nom_layout = QVBoxLayout(nom_widget)
            nom_layout.setContentsMargins(14, 4, 4, 4)
            nom_layout.setSpacing(0)
            lbl_nom = QLabel(item.get("Nom", ""))
            lbl_nom.setFont(QFont("Segoe UI", 12, QFont.Bold))
            lbl_prenom = QLabel(item.get("Prenom", ""))
            lbl_prenom.setFont(QFont("Segoe UI", 11))
            lbl_prenom.setStyleSheet("color:#777;")
            nom_layout.addWidget(lbl_nom)
            nom_layout.addWidget(lbl_prenom)
            self.table.setCellWidget(row, 1, nom_widget)

            self.table.setItem(row, 2, self._cell(item.get("Niveau", "")))
            self.table.setItem(row, 3, self._cell(item.get("Moyennes Semestres", "")))

            # Moyenne annuelle en bleu gras
            moy_item = QTableWidgetItem(item.get("Moyenne Annuelle", ""))
            moy_item.setForeground(QColor("#1a6fcf"))
            moy_item.setFont(QFont("Segoe UI", 12, QFont.Bold))
            moy_item.setTextAlignment(Qt.AlignCenter)
            self.table.setItem(row, 4, moy_item)

            self.table.setItem(row, 5, self._cell(str(item.get("Rang", ""))))

            mention = item.get("Mention", "")
            decision = item.get("Decision", "")
            
            # Couleurs dynamiques
            c_mention = "#22a855" if "Très Bien" in mention else ("#1a6fcf" if "Bien" in mention else "#888888")
            if not mention: c_mention = "#e05252"
            c_decision = "#22a855" if decision == "Admis" else "#e05252"

            self.table.setCellWidget(row, 6, self._badge(mention, c_mention))
            self.table.setCellWidget(row, 7, self._badge(decision, c_decision))
        
    def _cell(self, text):
        item = QTableWidgetItem(text)
        item.setFont(QFont("Segoe UI", 12))
        item.setTextAlignment(Qt.AlignVCenter | Qt.AlignLeft)
        return item

    def _badge(self, text, color):
        container = QWidget()
        lay = QHBoxLayout(container)
        lay.setContentsMargins(14, 4, 4, 4)
        lbl = QLabel(text)
        lbl.setFont(QFont("Segoe UI", 11, QFont.Bold))
        lbl.setAlignment(Qt.AlignCenter)
        lbl.setMinimumHeight(26)
        lbl.setStyleSheet(f"""
            color: {color};
            border: 1.5px solid {color};
            border-radius: 5px;
            padding: 2px 8px;
        """)
        lay.addWidget(lbl)
        lay.addStretch()
        return container



#  FENÊTRE PRINCIPALE

class SGNAnalyzer(QMainWindow):
    """
    Fenêtre principale de l'application.
    Gère l'intégration de l'éditeur de code, de la console et des résultats.
    """
    def __init__(self):
        super().__init__()
        self.current_file = None # Fichier SGN actuellement ouvert
        self.last_results = []   # Cache des derniers résultats d'analyse
        self.setWindowTitle("SGN Analyzer - Master 1 Compilation")
        self.setMinimumSize(1200, 700)
        self.resize(1280, 800)
        self._build_ui()
        self._apply_global_style()

    def _apply_global_style(self):
        self.setStyleSheet("""
            QMainWindow { background: #f0f2f5; }
            QWidget     { background: #f0f2f5; }
        """)

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QVBoxLayout(central)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # ── NAVBAR ──
        navbar = self._build_navbar()
        main_layout.addWidget(navbar)

        # ── CONTENU : éditeur gauche + panneau droit ──
        content = QWidget()
        content.setStyleSheet("background:#f0f2f5;")
        content_layout = QHBoxLayout(content)
        content_layout.setContentsMargins(20, 18, 20, 18)
        content_layout.setSpacing(18)

        # Panneau gauche : éditeur
        self.editor = CodeEditor()
        self.editor.setMinimumWidth(380)
        self.editor.setMaximumWidth(440)
        content_layout.addWidget(self.editor)

        # Panneau droit : console + résultats
        right = QWidget()
        right.setStyleSheet("background:#f0f2f5;")
        right_layout = QVBoxLayout(right)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_layout.setSpacing(16)

        self.console = ConsolePanel()
        self.console.setFixedHeight(138)
        right_layout.addWidget(self.console)

        self.results = ResultsPanel()
        right_layout.addWidget(self.results, 1)

        content_layout.addWidget(right, 1)
        main_layout.addWidget(content, 1)

    def _build_navbar(self):
        navbar = QWidget()
        navbar.setFixedHeight(52)
        navbar.setStyleSheet("""
            QWidget {
                background: #ffffff;
                border-bottom: 1px solid #e0e3e8;
            }
        """)

        layout = QHBoxLayout(navbar)
        layout.setContentsMargins(24, 0, 24, 0)
        layout.setSpacing(0)

        # Titre
        title = QLabel()
        title.setText('<span style="color:#1a6fcf; font-size:17px; font-weight:700;">SGN Analyzer</span>'
                      '<span style="color:#111; font-size:17px; font-weight:700;"> – Master 1 Compilation</span>')
        title.setTextFormat(Qt.RichText)
        title.setStyleSheet("border:none; background:transparent;")
        layout.addWidget(title)
        layout.addStretch()

        # Liens de navigation
        nav_items = [("Upload .sgn", self.upload_file, False), ("Save", self.save_file, False),
                     ("Run Analysis", self.run_analysis, True), ("Export CSV", self.export_csv, False)]
        for label, callback, active in nav_items:
            btn = QPushButton(label)
            btn.clicked.connect(callback)
            btn.setFont(QFont("Segoe UI", 11, QFont.Bold if active else QFont.Normal))
            if active:
                btn.setStyleSheet("""
                    QPushButton {
                        color: #1a6fcf;
                        border: none;
                        border-bottom: 2px solid #1a6fcf;
                        background: transparent;
                        padding: 0 12px;
                        font-weight: bold;
                    }
                """)
            else:
                btn.setStyleSheet("""
                    QPushButton {
                        color: #555;
                        border: none;
                        background: transparent;
                        padding: 0 12px;
                    }
                    QPushButton:hover {
                        color: #111;
                        background: #f0f2f5;
                        border-radius: 6px;
                    }
                """)
            btn.setFixedHeight(52)
            layout.addWidget(btn)

        layout.addSpacing(16)
        
        return navbar

    def upload_file(self):
        """
        Ouvre une boîte de dialogue pour sélectionner un fichier .sgn
        et charge son contenu dans l'éditeur.
        """
        file_path, _ = QFileDialog.getOpenFileName(self, "Ouvrir fichier SGN", "", "SGN Files (*.sgn);;All Files (*)", options=QFileDialog.DontUseNativeDialog)
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                self.editor.set_code(content)
                self.current_file = file_path
                self.editor.set_filename(os.path.basename(file_path))
                self.results.populate_table([])
                self.console.display_logs([])
            except Exception as e:
                QMessageBox.critical(self, "Erreur", str(e))

    def save_file(self):
        """
        Sauvegarde le contenu de l'éditeur dans le fichier actuel.
        Si aucun fichier n'est défini, ouvre une boîte de dialogue pour "Enregistrer sous".
        """
        if not self.current_file:
            self.current_file, _ = QFileDialog.getSaveFileName(self, "Sauvegarder", "", "SGN Files (*.sgn);;All Files (*)", options=QFileDialog.DontUseNativeDialog)
            if not self.current_file:
                return False
            self.editor.set_filename(os.path.basename(self.current_file))
        try:
            content = self.editor.get_code()
            if content.endswith('\n'): content = content[:-1]
            with open(self.current_file, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except Exception as e:
            QMessageBox.critical(self, "Erreur", str(e))
            return False

    def run_analysis(self):
        """
        Sauvegarde le fichier en cours et lance l'exécutable d'analyse (C).
        Parse le résultat JSON et met à jour l'interface graphique.
        """
        if not self.current_file and len(self.editor.get_code().strip()) == 0:
            QMessageBox.warning(self, "Avertissement", "Veuillez ouvrir ou écrire un fichier avant d'analyser.")
            return
        if not self.save_file():
            return
            
        result_data = run_parser(self.current_file)
        
        erreurs = result_data.get("erreurs", [])
        self.console.display_logs(erreurs)
        
        self.last_results = []
        for niveau_data in result_data.get("niveaux", []):
            niveau = niveau_data.get("niveau", "")
            for etud in niveau_data.get("etudiants", []):
                semestres_str = " | ".join([f"{sem.get('id', '')}: {sem.get('moyenne', 0):.2f}" for sem in etud.get("semestres", [])])
                nom_complet = f"{etud.get('nom', '')} {etud.get('prenom', '')}".strip()
                
                self.last_results.append({
                    "Matricule": etud.get("matricule", ""),
                    "Nom": etud.get("nom", ""),
                    "Prenom": etud.get("prenom", ""),
                    "Niveau": niveau,
                    "Moyennes Semestres": semestres_str,
                    "Moyenne Annuelle": f"{etud.get('moyenne_annuelle', 0):.2f}",
                    "Rang": etud.get("rang", ""),
                    "Mention": etud.get("mention", ""),
                    "Decision": etud.get("decision", "")
                })
        self.results.populate_table(self.last_results)

    def export_csv(self):
        """
        Exporte les résultats de la dernière analyse au format CSV
        vers un chemin spécifié par l'utilisateur.
        """
        if not self.last_results:
            QMessageBox.warning(self, "Avertissement", "Aucune donnée à exporter. Veuillez d'abord analyser un fichier.")
            return
        csv_path, _ = QFileDialog.getSaveFileName(self, "Exporter CSV", "", "CSV Files (*.csv);;All Files (*)", options=QFileDialog.DontUseNativeDialog)
        if not csv_path:
            return
        try:
            with open(csv_path, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=self.last_results[0].keys())
                writer.writeheader()
                writer.writerows(self.last_results)
            QMessageBox.information(self, "Succès", f"Les résultats ont été exportés vers:\n{csv_path}")
        except Exception as e:
            QMessageBox.critical(self, "Erreur d'export", str(e))



#  POINT D'ENTRÉE
