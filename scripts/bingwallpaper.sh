#!/bin/bash
# author: Whizzzkid (me@nishantarora.in)

# https://github.com/hillyu/hill/blob/0275d35e46ddeb4ebc993fc692cd28d9d81c6e74/bin/bingwallpaper

# Base URL.
bing="http://www.bing.com"

# API end point.
api="/HPImageArchive.aspx?"

# Response Format (json|xml).
format="" # 目前此参数不起作用 "&format=js"

# For day (0=current; 1=yesterday... so on).
day="&idx=0"

# Market for image.
market="&mkt=en-US"

# API Constant (fetch how many).
const="&n=1"

# Image extension.
extn=".jpg"

# Size.
size="1920x1080"

# Collection Path.
path="$HOME/Pictures/Bing/"

########################################################################
#### DO NOT EDIT BELOW THIS LINE #######################################
########################################################################

# Required Image Uri.
reqImg=$bing$api$format$day$market$const

# Logging.
echo "Pinging Bing API..."

# Fetching API response.
apiResp=$(curl -s -m 2 $reqImg)
if [ $? -gt 0 ]; then
  echo "Ping failed!"
  exit 1
fi

# Default image URL in case the required is not available.
defImgURL=$bing$(echo $apiResp | yq -p=xml '.images.image.url')

# Req image url (raw).
reqImgURL=$bing$(echo $apiResp | yq -p=xml '.images.image.urlBase')"_"$size$extn

# Image copyright.
copyright=$(echo $apiResp | yq -p=xml '.images.image.copyright')

# Checking if reqImgURL exists.
if ! wget --quiet --spider --max-redirect 0 $reqImgURL; then
  reqImgURL=$defImgURL
fi

# Logging.
echo "Bing Image of the day: $reqImgURL"

# Getting Image Name.
imgName=$(echo "$reqImgURL" | sed -e 's/.*[?&;]id=\([^&]*\).*/\1/' | grep -oe '[^\.]*\.[^\.]*$')

# Create Path Dir.
mkdir -p $path

if ! [ -e $path$imgName ]; then
  # Saving Image to collection.
  curl -L -s -m 2 -o $path$imgName $reqImgURL

  # Logging.
  echo "Saving image to $path$imgName"

  # Writing copyright.
  echo "$copyright" > $path${imgName/%.jpg/.txt}
  
  feh --bg-fill $path$imgName

  echo "New wallpaper set successfully for $XDG_CURRENT_DESKTOP."
else
  echo "Wallpaper already exists."
fi
