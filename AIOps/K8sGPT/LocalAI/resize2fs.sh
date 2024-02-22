

echo yes | parted /dev/sda ---pretend-input-tty resizepart 2 215GB

resize2fs /dev/sda2

https://www.privex.io/articles/how-to-resize-partition/
