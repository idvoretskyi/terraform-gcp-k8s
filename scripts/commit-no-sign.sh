#!/bin/bash
# Simple script to commit without signing

git -c commit.gpgsign=false commit -m "$*"
