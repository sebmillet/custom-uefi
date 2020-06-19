#!/usr/bin/bash
# vim: tw=80:ts=4:sw=4:et

#
# fpvar.sh
#
# Copyright Sébastien Millet, milletseb@laposte.net, 2020
#
# Prints out the fingerprint of certificates found in Secure Boot variables
# (those variables you can read with efi-readvar).
#

set -euo pipefail

TMP=
function cleanup {
    cd ..
    if [ -d "${TMP}" ]; then
        rm -rf "${TMP}"
    fi
}

trap cleanup EXIT

ONLYEXTRACT=n
E=${1:-}
if [ "${E}" == "-e" ]; then
    ONLYEXTRACT=y
    shift
fi

PRINTPERIOD=n
D=${1:-}
if [ "${D}" == "-d" ]; then
    PRINTPERIOD=y
    shift
fi

V=${1:-}

if [ -z "${V}" ]; then
    echo "Usage:"
    echo "  fpvar.sh [OPTIONS...] VAR"
    echo "Where VAR is one of PK, KEK, db or dbx"
    echo "Print out the current content of an UEFI variable, in a condensed"
    echo "form."
    echo
    echo "Options:"
    echo "  -e Extract certificates only (prints nothing)"
    echo "  -d Also prints validity period of certificates"
    echo
    echo "Examples:"
    echo "  fpvar.sh PK"
    echo "  fpvar.sh -d db"
    echo "  fpvar.sh -e KEK"
    exit
fi

if [ "${ONLYEXTRACT}" == "n" ]; then
    TMP=$(mktemp -d './fpvar-tmp.XXXXX')
    cd "${TMP}"
fi

efi-readvar -v "${V}" -o extract.esl > /dev/null
sig-list-to-certs extract.esl cert > /dev/null

if [ "${ONLYEXTRACT}" == "y" ]; then
    rm extract.esl
    exit 0
fi

set +e
nb=$(ls cert-[0-9]*.der 2> /dev/null | wc -l)
if [ "${nb}" == "0" ]; then
    echo "No certificate found in variable. Aborted."
    exit 1
fi
set -e

for f in $(ls cert-[0-9]*.der); do
    n=${f%.der}
    n=${n#cert-}
    subj=$(openssl x509 -inform der -in "${f}" -noout -subject)
    fp=$(openssl x509 -inform der -in "${f}" -noout -fingerprint)
    fp=${fp#SHA1 Fingerprint=}

    EXTRA=
    if [ "${PRINTPERIOD}" == "y" ]; then
        startdate=$(openssl x509 -inform der -in "${f}" -noout -startdate | \
            sed 's/notBefore=//')
        enddate=$(openssl x509 -inform der -in "${f}" -noout -enddate | \
            sed 's/notAfter=//')
        startdate=$(date -d"${startdate}" +%d/%m/%Y)
        enddate=$(date -d"${enddate}" +%d/%m/%Y)
        EXTRA="${startdate}->${enddate} "
    fi

    subj=${subj#*CN =}
    subj=${subj#*CN=}
    subj=${subj%%/*}
    subj=${subj# }
    subj=${subj% }
    echo "${EXTRA}${fp} [${subj}]"
done

