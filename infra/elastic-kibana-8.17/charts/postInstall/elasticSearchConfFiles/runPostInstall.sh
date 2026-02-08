exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_cluster/settings -H 'Content-Type: application/json' -d @/usr/share/extras/elasticSearchParameter1.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply elasticSearchParameter1.json"
else
  echo "elasticSearchParameter1.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_cluster/settings -H 'Content-Type: application/json' -d @/usr/share/extras/elasticSearchParameter2.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply elasticSearchParameter2.json"
else
  echo "elasticSearchParameter2.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_ilm/policy/tsgs-policy-delete -H 'Content-Type: application/json' -d @/usr/share/extras/tsgs-policy-delete.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply tsgs-policy-delete.json"
else
    echo "tsgs-policy-delete.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_ilm/policy/test-policy-delete -H 'Content-Type: application/json' -d @/usr/share/extras/test-policy-delete.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply test-policy-delete.json"
else
    echo "test-policy-delete.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_ilm/policy/tsgs-history-policy-delete -H 'Content-Type: application/json' -d @/usr/share/extras/tsgs-history-policy-delete.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply tsgs-history-policy-delete.json"
else
    echo "tsgs-history-policy-delete.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_ilm/policy/tsgs-app-write-policy-delete -H 'Content-Type: application/json' -d @/usr/share/extras/tsgs-app-write-policy-delete.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply tsgs-app-write-policy-delete.json"
else
    echo "tsgs-app-write-policy-delete.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_ingest/pipeline/add-timestamp-to-reality -H 'Content-Type: application/json' -d @/usr/share/extras/add-timestamp-to-reality.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply add-timestamp-to-reality.json"
else
  echo "add-timestamp-to-reality.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_index_template/app-nologformat-write -H 'Content-Type: application/json' -d @/usr/share/extras/app-nologformat-write.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply app-nologformat-write.json"
else
  echo "app-nologformat-write.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_index_template/app-write -H 'Content-Type: application/json' -d @/usr/share/extras/app-write.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply app-write.json"
else
  echo "app-write.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_index_template/reality-history -H 'Content-Type: application/json' -d @/usr/share/extras/reality-history.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply reality-history.json"
else
  echo "reality-history.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_ingest/pipeline/structured-metadata-format -H 'Content-Type: application/json' -d @/usr/share/extras/structured-metadata-format.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply structured-metadata-format.json applied"
else
  echo "structured-metadata-format.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_index_template/app-adlg-write -H 'Content-Type: application/json' -d @/usr/share/extras/app-adlg-write.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply app-adlg-write.json applied"
else
  echo "app-adlg-write.json applied"
fi

exit_code=$(curl -s -o /dev/null -w '%{http_code}\n' -XPUT http://elastic-kibana-elasticsearch:9200/_index_template/app-elastictest-write -H 'Content-Type: application/json' -d @/usr/share/extras/elastic-test.json)
if [[ "$exit_code" != "200" ]]
then
  echo "unable to apply elastic-test.json applied"
  exit 1
else
  echo "elastic-test.json applied"
fi


exit 0


