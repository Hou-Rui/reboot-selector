#!/bin/sh

PREFIX="${1:-/usr}"
PROJECT='reboot-selector'
TMPRUN='run.sh'

SRC_DIR="$PREFIX/share/$PROJECT"
APPL_DIR="$PREFIX/share/applications"

mkdir -p "$SRC_DIR"
for src_file in *.py *.qml; do
  install -Dm 644 "$src_file" "$SRC_DIR"
done
install -Dm 644 ./*.desktop -t "$APPL_DIR"

printf "#!/bin/sh\npython \"%s\"" "$SRC_DIR/main.py" >"$TMPRUN"
install -Dm 755 "$TMPRUN" -T "$PREFIX/bin/$PROJECT"
rm "$TMPRUN"
