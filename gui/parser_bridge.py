import subprocess
import json
import os

def run_parser(file_path):
    """
    Exécute le parseur C (sgn) sur le fichier donné et retourne le résultat JSON.
    
    Args:
        file_path (str): Chemin vers le fichier .sgn à analyser.
        
    Returns:
        dict: Le résultat de l'analyse sous forme de dictionnaire Python.
    """
    # Le binaire se trouve dans le dossier src/ qui est au même niveau que gui/
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    parser_executable = os.path.join(base_dir, 'src', 'sgn')
    
    if not os.path.exists(parser_executable):
        return {
            "erreurs": [
                f"L'exécutable {parser_executable} n'a pas été trouvé. Avez-vous compilé avec 'make' ?"
            ]
        }
    
    try:
        # Exécution du binaire avec le fichier en argument
        result = subprocess.run(
            [parser_executable, file_path],
            capture_output=True,
            text=True,
            check=False # On ne lève pas d'exception si le code de retour n'est pas 0 (le parseur gère ses erreurs)
        )
        
        # Le binaire renvoie du JSON sur stdout
        output = result.stdout.strip()
        
        # Si le binaire a crashé ou n'a rien renvoyé
        if not output:
            error_msg = result.stderr.strip() if result.stderr else "Le parseur n'a renvoyé aucune sortie."
            return {"erreurs": [f"Erreur d'exécution: {error_msg}"]}
            
        # Parse le JSON
        try:
            data = json.loads(output)
            # Ajout des erreurs depuis stderr si le binaire écrit dedans
            if result.stderr:
                erreurs_stderr = [line.strip() for line in result.stderr.strip().split('\n') if line.strip()]
                if "erreurs" not in data:
                    data["erreurs"] = []
                data["erreurs"].extend(erreurs_stderr)
            return data
        except json.JSONDecodeError as e:
            return {
                "erreurs": [
                    f"Erreur de décodage JSON de la sortie du parseur : {str(e)}",
                    f"Sortie brute : {output[:200]}..."
                ]
            }
            
    except Exception as e:
        return {"erreurs": [f"Erreur inattendue : {str(e)}"]}
