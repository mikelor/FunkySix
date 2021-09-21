# $1 - subscriptionName
# $2 - projectName
# $3 - projectEnvironment [dev, qa, prod]
#./deployMoclips.sh <subscriptionName> <projectName> <projectEnvironment>
az account set -s $1
az group create -l westus2 -g $2-$3-grp
az deployment group create -g $2-$3-grp  \
  --template-file funkysix.json \
  --parameters "{\"projectName\": {\"value\": \"$2\"}, \"projectEnvironment\": {\"value\": \"$3\"} }" \
  $4