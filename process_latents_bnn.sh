LIST=$(ls latent*csv)
for L in $LIST; do awk -F, 'BEGIN {OFS=","} {$1=""; print substr($0,2)}' ${L} > clean_${L}; echo $L; done;


LIST=$(ls filelist*csv)
for FL in $LIST; do cat $FL | awk -v MV=0 -F, 'BEGIN {OFS=","} {MV=$1} {gsub(/.*6m_/,"UUID_",MV)} {gsub(/\.png/,"",MV)}{print $1,$2,$3,$4,$5,$6,MV}' > uuid_${FL}; done;

sed -i 's/,relative_path/,uuid/g' uuid_filelist_L*

for KK in $LIST; do ID=$(echo $KK | sed 's/.*_//g' | sed 's/\.csv//g'); paste --delimiters=, uuid_filelist_${ID}.csv clean_latents_${ID}.csv > latents_uuid_${ID}.csv; done;