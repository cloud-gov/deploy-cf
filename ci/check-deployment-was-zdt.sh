#!/bin/bash

# timestamp/timestamp will look like 2021-12-31 23:59:59 -0000 UTC
# date wants                         2021-12-31 23:59:59-0000
START_TIME=$(date -d "`cat timestamp/timestamp | sed -r 's/ ([+-][[:digit:]]{4}) ([A-Z][SD]T|UTC)/\1/'`" +%s)

stats=$(aws cloudwatch get-metric-data --start-time $START_TIME --end-time `date +%s` --metric-data-queries '
{
  "Id": "m1",
  "MetricStat": {
    "Metric": {
      "Namespace": "AWS/Route53",
      "MetricName": "HealthCheckStatus",
      "Dimensions": [
        {
          "Name": "HealthCheckId",
          "Value": "'${HEALTH_CHECK_ID}'"
        }
      ]
    },
    "Period": 1,
    "Stat": "Average"
  }
}' | jq '.MetricDataResults[0].Values[]')

for stat in stats; do
  if [[ stat -lt 1 ]]; then
    exit 1
  fi
done