#!/bin/bash
#
# This file is part of Opal and has been released into the public domain.
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2021 Mirian Margiani
#
# See https://github.com/Pretty-SFOS/opal/blob/main/snippets/opal-render-icons.md
# for documentation.

# Run this script from the same directory where your icon sources are located,
# e.g. <app>/icon-src.

source ~/src/Sailfish/opal/opal/snippets/opal-render-icons.sh
cFORCE=false

for i in raw/*.svg; do
    scour "$i" > "${i#raw/}"
done

cNAME="app icon"
cITEMS=(harbour-captains-log)
cRESOLUTIONS=(86 108 128 172)
cTARGETS=(../icons/RESXxRESY)
render_batch

cNAME="mood icons"
cITEMS=(mood-{0,1,2,3,4,5})
cRESOLUTIONS=(112)
cTARGETS=(../qml/images)
render_batch

cNAME="cover background"
cITEMS=(cover-bg)
cRESOLUTIONS=(460x736)
cTARGETS=(../qml/images)
render_batch
