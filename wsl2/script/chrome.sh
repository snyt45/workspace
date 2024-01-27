#!/bin/bash
while true
do
  cat $HOME/chrome | xargs -I % sh -c '"/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" %'
done
