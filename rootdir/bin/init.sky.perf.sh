#!/vendor/bin/sh
#
# Copyright (C) 2024 Paranoid Android
# SPDX-License-Identifier: Apache-2.0
#

# Runs after init.kernel.post_boot-ravelin.sh. Let both clusters idle at
# their lowest step instead of the 672/691 MHz floor, and only jump to
# hispeed once a cluster is really busy.
for policy in /sys/devices/system/cpu/cpufreq/policy0 /sys/devices/system/cpu/cpufreq/policy6; do
    [ -d $policy ] || continue
    cat $policy/cpuinfo_min_freq > $policy/scaling_min_freq
    echo 90 > $policy/walt/hispeed_load
done
