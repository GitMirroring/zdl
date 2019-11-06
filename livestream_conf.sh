#!/bin/bash -i
#
# ZigzagDownLoader (ZDL)
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 3 of the License, 
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see http://www.gnu.org/licenses/. 
# 
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

live_streaming_chan=(
    "La 7"
    "Rai 1"
    "Rai 2"
    "Rai 3"
    "Rai 4"
    "Rai 5"
    "Rai News 24"
    "Rai Sport"
    "Rai Sport+ HD"
    "Rai Movie"
    "Rai Premium"
    "Rai Yoyo"
    "Rai Gulp"
    "Rai Storia"
    "Rai Play"
)

live_streaming_url=(
    https://www.la7.it/dirette-tv
    https://www.raiplay.it/dirette/rai1
    https://www.raiplay.it/dirette/rai2
    https://www.raiplay.it/dirette/rai3
    https://www.raiplay.it/dirette/rai4
    https://www.raiplay.it/dirette/rai5
    https://www.raiplay.it/dirette/rainews24
    https://www.raiplay.it/dirette/raisport
    https://www.raiplay.it/dirette/raisportpiuhd
    https://www.raiplay.it/dirette/raimovie
    https://www.raiplay.it/dirette/raipremium
    https://www.raiplay.it/dirette/raiyoyo
    https://www.raiplay.it/dirette/raigulp
    https://www.raiplay.it/dirette/raistoria
    https://www.raiplay.it/dirette/raiplay
)
