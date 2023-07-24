#!/bin/bash
while true
do
  # 文字化け対応
  # see: https://nodamushi.hatenablog.com/entry/2018/01/12/195253
  cat $HOME/clip | iconv -f UTF-8 -t CP932 | /mnt/c/Windows/system32/clip.exe
done
