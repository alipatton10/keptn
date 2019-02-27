#!/bin/bash

entries=$(curl https://$1/api/v1/deployment/installer/agent/connectioninfo?Api-Token=$2 | jq -r '.communicationEndpoints[]')

mkdir serviceEntry_tmp
touch serviceEntry_tmp/hosts
touch serviceEntry_tmp/service_entries_oneagent.yml
touch serviceEntry_tmp/service_entries

cat ../manifests/istio/service_entries_tpl/part1 >> serviceEntry_tmp/service_entries_oneagent.yml

dthost=$(echo $1 | sed 's,/.*,,')
echo -e "  - $dthost" >> serviceEntry_tmp/hosts
cat ../manifests/istio/service_entries_tpl/service_entry_tmpl | sed 's~ENDPOINT_PLACEHOLDER~'"$dthost"'~' >> serviceEntry_tmp/service_entries

for row in $entries; do
    row=$(echo $row | sed 's~https://~~')
    row=$(echo $row | sed 's~/communication~~')
    row=$(echo $row | sed 's/:.*//')
    echo -e "  - $row" >> serviceEntry_tmp/hosts
    cat ../manifests/istio/service_entries_tpl/service_entry_tmpl | sed 's~ENDPOINT_PLACEHOLDER~'"$row"'~' >> serviceEntry_tmp/service_entries
done

cat serviceEntry_tmp/hosts >> serviceEntry_tmp/service_entries_oneagent.yml
cat ../manifests/istio/service_entries_tpl/part2 >> serviceEntry_tmp/service_entries_oneagent.yml

cat serviceEntry_tmp/hosts >> serviceEntry_tmp/service_entries_oneagent.yml
cat ../manifests/istio/service_entries_tpl/part3 >> serviceEntry_tmp/service_entries_oneagent.yml

cat serviceEntry_tmp/service_entries >> serviceEntry_tmp/service_entries_oneagent.yml

cp serviceEntry_tmp/service_entries_oneagent.yml ../manifests/istio/service_entries_oneagent.yml

kubectl apply -f serviceEntry_tmp/service_entries_oneagent.yml

rm -rf serviceEntry_tmp
