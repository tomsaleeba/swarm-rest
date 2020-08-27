#!/bin/bash
# deletes ES snapshots from S3 matching your fragment, presumably they're old
set -euo pipefail
cd `dirname "$0"`

host=${HOST:-localhost:9200}
repoName=${REPO_NAME:-swarm-s3-backup}
snapshotListingFile=`mktemp --suffix=snaplist`
yearFilterFile=`mktemp --suffix=yearfilter`
yearToFilterFor=${1:?first param must be year to filter for, e.g. 2018}
currentYear=`date +%Y`

if [ $yearToFilterFor == $currentYear ]; then
  echo "[ERROR] you can't delete snapshots for the current year: $yearToFilterFor"
  exit 1
fi

echo -e "Using
  snapshot listing file: $snapshotListingFile
  host:                  $host
  repo name:             $repoName\n"

echo "[INFO] Getting list of snapshots"
curl "http://$host/_snapshot/$repoName/_all" > $snapshotListingFile

echo "[INFO] Filtering for list of snapshots to delete using: $yearToFilterFor"
jq -r '.snapshots | .[].snapshot' $snapshotListingFile \
  | grep "\.$yearToFilterFor" \
  > $yearFilterFile

foundCount=$(wc -l $yearFilterFile | cut -f 1 -d ' ')
echo "[INFO] Found a total of $foundCount snapshots to delete, here's a sample"
head -n 4 $yearFilterFile

# thanks https://stackoverflow.com/a/226724/1410035
echo -e "\nDo you want to continue deleting $foundCount snapshots?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) echo "cancelled"; exit;;
    esac
done

cat $yearFilterFile \
  | xargs \
    --max-lines=1 \
    --replace \
    bash -c "
      echo -en '\n[INFO] deleting snapshot {}, starting at ';
      date +%H:%M:%S ;
      curl -X DELETE http://$host/_snapshot/$repoName/{}"

echo -e "\nDone, deleted $foundCount snapshots"
