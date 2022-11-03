#!/bin/bash
# Automation for finalize_branch_for_release.sh.
# Sets up local environment, runs the finalization script and submits the results.
# WIP:
# - does not submit, only sends to gerrit.

# set -ex

function revert_to_unfinalized_state() {
    repo forall -c '\
        git checkout . ; git revert --abort ; git clean -fdx ;\
        git checkout @ ; git b fina-step1 -D ; git reset --hard; \
        repo start fina-step1 ; git checkout @ ; git b fina-step1 -D ;\
        previousHash="$(git log --format=%H --no-merges --max-count=100 --grep ^FINALIZATION_STEP_1_SCRIPT_COMMIT | tr \n \040)" ;\
        if [[ $previousHash ]]; then git revert --no-commit --strategy=ort --strategy-option=ours $previousHash ; fi ;'
}

function commit_changes() {
    repo forall -c '\
        if [[ $(git status --short) ]]; then
            repo start fina-step1 ;
            git add -A . ;
            git commit -m FINALIZATION_STEP_1_SCRIPT_COMMIT -m WILL_BE_AUTOMATICALLY_REVERTED ;
            repo upload --cbr --no-verify -t -y . ;
            git clean -fdx ; git reset --hard ;
        fi'
}

function finalize_step_1_main() {
    local top="$(dirname "$0")"/../..

    repo selfupdate

    revert_to_unfinalized_state

    # vndk etc finalization
    source $top/build/make/finalize-aidl-vndk-sdk-resources.sh

    # move all changes to fina-step1 branch and commit with a robot message
    commit_changes
}

finalize_step_1_main
