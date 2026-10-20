#!/usr/bin/env bash
# SCRATCH / evidence (part 4, S41/S42): for each component in a graph-probe output, report whether its jar is already in the part-2 Gradle home cache, else its size by HEAD (bytes). Nothing is downloaded.
# usage: bash s41-graph-sizes.sh <graph-probe-output> <cache-files-2.1-dir>
IN=$1; H=$2
cfg=""
while read -r line; do
  case "$line" in
    "## CONFIG"*) cfg=${line#\#\# CONFIG }; echo "## $cfg";;
    COMP\ :*) ;;
    COMP\ *) c=${line#COMP }; g=${c%%:*}; r=${c#*:}; n=${r%%:*}; v=${r#*:}
      if [ -d "$H/$g/$n/$v" ] && find "$H/$g/$n/$v" -name '*.jar' | grep -q .; then echo -e "CACHED\t$c"; continue; fi
      p="$(echo $g | tr . /)/$n/$v/$n-$v.jar"
      s=$(curl -fsSI --max-time 20 "https://repo1.maven.org/maven2/$p" | tr -d '\r' | awk 'tolower($1)=="content-length:"{print $2}' | tail -1)
      [ -z "$s" ] && s=$(curl -fsSI --max-time 20 "https://plugins.gradle.org/m2/$p" | tr -d '\r' | awk 'tolower($1)=="content-length:"{print $2}' | tail -1)
      echo -e "${s:-NOJAR}\t$c";;
  esac
done < "$IN"
