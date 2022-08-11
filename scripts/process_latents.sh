conda activate georef
LIST=$(ls L*)
LIST=$(ls | grep trained)
echo $LIST
for KK in $LIST; do cp latent2csv.py ${KK}/latent2csv.py; done;
for KK in $LIST; do cd ${KK}/; python latent2csv.py; cd ..; done;

for KK in $LIST; do cd ${KK}/; RR=$(cat configuration.yaml | grep sigma | sed 's/.*sigma: //g' | grep -v 0.04 | sed 's/\.0//g'); echo "Renaming CSV for "$RR; rename "s/\.csv/_L${RR}m\.csv/g" *.csv; cd ..; done;