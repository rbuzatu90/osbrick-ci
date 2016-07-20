source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.$JOB_TYPE.txt
source /home/jenkins-slave/tools/keystonerc_admin
source /usr/local/src/osbrick-ci/jobs/library.sh

if [ -z "$ZUUL_CHANGE" ] || [ -z "$ZUUL_PATCHSET" ] || [ -z "$JOB_TYPE" ]; then
    echo "Missing parameters! ZUUL_CHANGE: $ZUUL_CHANGE, ZUUL_PATCHSET: $ZUUL_PATCHSET, JOB_TYPE: $JOB_TYPE"
    exit 1
fi

logs_project=os-brick

set +e

ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "mkdir -p /openstack/logs/${hyperv01%%[.]*}"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "sudo chown -R nobody:nogroup /openstack/logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "sudo chmod -R 777 /openstack/logs"

set -f

run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS "powershell -executionpolicy remotesigned C:\OpenStack\osbrick-ci\HyperV\scripts\collect_logs.ps1 $FLOATING_IP" 


set +f
echo "Collecting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "/home/ubuntu/bin/collect_logs.sh"

if [ "$IS_DEBUG_JOB" != "yes" ]; then
    LOGDEST="/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$JOB_TYPE"
else
    TIMESTAMP=$(date +%d-%m-%Y_%H-%M)
    LOGDEST="/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$JOB_TYPE/$TIMESTAMP" 
fi

echo "Creating logs destination folder"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "rm -rf $LOGDEST"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "mkdir -p $LOGDEST"

echo "Downloading logs"
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$VMID.tar.gz"

echo "Uploading logs"
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "aggregate-$VMID.tar.gz" logs@logs.openstack.tld:$LOGDEST/aggregate-logs.tar.gz
gzip -9 /home/jenkins-slave/logs/console-$ZUUL_UUID-$JOB_TYPE.log
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY \
    "/home/jenkins-slave/logs/console-$ZUUL_UUID-$JOB_TYPE.log.gz" \
    logs@logs.openstack.tld:$LOGDEST/console.log.gz && rm -f /home/jenkins-slave/logs/console-$ZUUL_UUID-$JOB_TYPE.log.gz

echo "Extracting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "tar -xzf $LOGDEST/aggregate-logs.tar.gz -C $LOGDEST/"

echo "Uploading temporary logs"
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY  \
    "/home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$JOB_TYPE-$hyperv01" \
    logs@logs.openstack.tld:$LOGDEST/hyperv-build-log-$ZUUL_UUID-$JOB_TYPE-$hyperv01.log
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY  \
    "/home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID-$JOB_TYPE" logs@logs.openstack.tld:$LOGDEST/devstack-build-log-$ZUUL_UUID-$JOB_TYPE.log

echo "Fixing permissions on all log files"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY \
    logs@logs.openstack.tld "chmod a+rx -R $LOGDEST"

echo "Removing local copy of aggregate logs"
rm -fv aggregate-$VMID.tar.gz

echo "Removing HyperV temporary console logs.."
rm -fv /home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$JOB_TYPE-$hyperv01

echo "Removing temporary devstack log.."
rm -fv /home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID-$JOB_TYPE

echo `date -u +%H:%M:%S`
set -e
