#!/usr/bin/env bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
help_message=$(cat << EOF
Usage: $0
EOF
)
SECONDS=0

log "$0 $*"


. ./utils/parse_options.sh

. ./db.sh
. ./path.sh
. ./cmd.sh


if [ $# -gt 1 ]; then
  log "${help_message}"
  exit 2
fi

# aishell data preparation
#if [ -z "${AISHELL}" ]; then
#  log "Error: \$AISHELL is not set in db.sh."
#  exit 2
#fi
# include both training, dev, and test set
#local/aishell_data_prep.sh

# aidatatang data preparation
#if [ -z "${AIDATATANG}" ]; then
#  log "Error: \$AIDATATANG is not set in db.sh."
#  exit 2
#fi
# include both training, dev, and test set
#local/aidatatang_data_prep.sh

# st_cmd data preparation
#if [ -z "${ST_CMD}" ]; then
#  log "Error: \$ST_CMD is not set in db.sh."
#  exit 2
#fi
# only have training and dev set
#local/st_cmds_data_prep.sh

# aishell4  data preparation
#if [ -z "${AISHELL4}" ]; then
#  log "Error: \$AISHELL4 is not set in db.sh."
#  exit 2
#fi
# only have training and test set
#local/aishell4_data_prep.sh --no_overlap true

# alimeeting  data preparation
if [ -z "${AliMeeting}" ]; then
    log "Error: \$AliMeeting is not set in db.sh."
    exit 2
fi
# only have training and test set
local/alimeeting_data_prep.sh --no_overlap true --tgt test
local/alimeeting_data_prep.sh --no_overlap true --tgt train

# combine all training set
#utils/combine_data.sh data/train data/*_train

# combine all dev set
#utils/combine_data.sh data/test data/*_test


log "Successfully finished. [elapsed=${SECONDS}s]"
