#!/usr/bin/bash
# vim: tw=80:ts=4:sw=4:et

#
# fpcer.sh
#
# Copyright Sébastien Millet, milletseb@laposte.net, 2020
#
# Prints out the fingerprint of certificate.
#

set -euo pipefail

C=${1-:}

subj=$(openssl x509 -in "${C}" -noout -subject)
subj=${subj#*CN =}
subj=${subj#*CN=}
subj=${subj%%/*}
subj=${subj# }
subj=${subj% }
fp=$(openssl x509 -in "${C}" -noout -fingerprint | sed 's/SHA1 Fingerprint=//')

echo "${fp} [${subj}]"

