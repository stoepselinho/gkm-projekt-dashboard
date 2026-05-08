#!/bin/bash

# In den Ordner des Skripts wechseln
cd "$(dirname "$0")"

# Prüfen ob Änderungen vorhanden
if git diff --quiet dashboard.html && git diff --cached --quiet dashboard.html; then
  osascript -e 'display dialog "Keine Änderungen an dashboard.html gefunden — nichts zu speichern." buttons {"OK"} default button "OK" with title "Dashboard aktualisieren"'
  exit 0
fi

# Letzte Version ermitteln und hochzählen
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0")
MAJOR=$(echo "$LAST_TAG" | sed 's/v//' | cut -d. -f1)
MINOR=$(echo "$LAST_TAG" | sed 's/v//' | cut -d. -f2)
NEXT_MINOR=$((MINOR + 1))
NEXT_VERSION="v${MAJOR}.${NEXT_MINOR}"

# Beschreibung abfragen
RESULT=$(osascript <<EOF
tell application "System Events"
  set dlg to display dialog "Was wurde geändert?" & return & "(wird als ${NEXT_VERSION} gespeichert)" ¬
    default answer "" ¬
    with title "Dashboard aktualisieren" ¬
    buttons {"Abbrechen", "Speichern & Hochladen"} ¬
    default button "Speichern & Hochladen"
  if button returned of dlg is "Abbrechen" then
    return "CANCELLED"
  end if
  return text returned of dlg
end tell
EOF
)

# Abgebrochen oder leer
if [ "$RESULT" = "CANCELLED" ] || [ -z "$RESULT" ]; then
  exit 0
fi

# Git: hinzufügen, committen, pushen, taggen
git add dashboard.html

git commit -m "${NEXT_VERSION} — ${RESULT}" --quiet

git push --quiet 2>&1
PUSH_STATUS=$?

if [ $PUSH_STATUS -ne 0 ]; then
  osascript -e "display dialog \"Fehler beim Hochladen zu GitHub.\\nBitte Internetverbindung prüfen.\" buttons {\"OK\"} default button \"OK\" with title \"Fehler\" with icon stop"
  exit 1
fi

git tag "${NEXT_VERSION}" -m "${NEXT_VERSION} — ${RESULT}"
git push origin "${NEXT_VERSION}" --quiet 2>&1

# Erfolgsmeldung
osascript -e "display dialog \"✓ ${NEXT_VERSION} wurde gespeichert.\\n\\n${RESULT}\\n\\nGitHub Pages wird in ~1 Minute aktualisiert.\" buttons {\"OK\"} default button \"OK\" with title \"Dashboard aktualisiert\""
