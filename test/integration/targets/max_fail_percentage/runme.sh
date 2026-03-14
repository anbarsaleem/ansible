#!/usr/bin/env bash

set -eux

# Test: max_fail_percentage with block/rescue/always
#
# host1 fails in block, then fails in rescue, triggering
# max_fail_percentage: 24 (1/4 = 25% > 24%).
# - rescue and always tasks should still execute for ALL hosts
# - the "Marker task" after the block should NOT run

set +e
ansible-playbook test_nested.yml -i inventory "$@" > output.log 2>&1
result=$?
set -e

cat output.log

# Playbook should exit with non-zero
if [ $result -eq 0 ]; then
    echo "FAIL: Playbook should have failed but succeeded"
    exit 1
fi

# Check that Marker task did NOT run for any host
if grep -q "Marker task" output.log; then
    echo "FAIL: Marker task ran but should have been skipped by max_fail_percentage"
    exit 1
fi

# Check that rescue executed for host1
if ! grep -q "rescue fail" output.log; then
    echo "FAIL: rescue task did not execute for host1"
    exit 1
fi

# Check that always tasks executed for ALL hosts
for host in host1 host2 host3 host4; do
    if ! grep -q "always ran on ${host}" output.log; then
        echo "FAIL: always task did not execute for ${host}"
        exit 1
    fi
done

# Check that we got the "NO MORE HOSTS LEFT" message
if ! grep -q "NO MORE HOSTS LEFT" output.log; then
    echo "FAIL: NO MORE HOSTS LEFT message not found in output"
    exit 1
fi

echo "Test passed!"
